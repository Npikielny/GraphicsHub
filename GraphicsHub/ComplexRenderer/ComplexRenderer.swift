//
//  ComplexRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import MetalKit

class ComplexRenderer: SinglyCappedRenderer {
    enum State {
        case juliaSet
        case mandelbrotSet
    }
    var juliaPipeline: MTLComputePipelineState!
    var mandelbrotPipeline: MTLComputePipelineState!
    
    var state: State = .juliaSet
    
    var c: SIMD2<Float> {
        let cReal = renderSpecificInputs![0] as! SliderInput
        let cImaginary = renderSpecificInputs![1] as! SliderInput
        return SIMD2<Float>(Float(cReal.output),Float(cImaginary.output))
    }
    var zoom: Float {
        Float((renderSpecificInputs![2] as! SliderInput).output)
    }
    var origin: SIMD2<Float> {
        let originX = renderSpecificInputs![3] as! SliderInput
        let originY = renderSpecificInputs![4] as! SliderInput
        return SIMD2<Float>(Float(originX.output),Float(originY.output))
    }
    var scalingFactor: Float {
        return Float((renderSpecificInputs![5] as! SliderInput).output)
    }
    func randomColor() -> SIMD3<Float> {
        return SIMD3<Float>(Float.random(in: 0...1),
                            Float.random(in: 0...1),
                            Float.random(in: 0...1))
    }
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size)
        let functions = createFunctions(names: "juliaSet", "mandelbrotSet")
        if let juliaFunction = functions[0], let mandelbrotFunction = functions[1] {
            do {
                juliaPipeline = try device.makeComputePipelineState(function: juliaFunction)
                mandelbrotPipeline = try device.makeComputePipelineState(function: mandelbrotFunction)
            } catch {
                print(error)
                fatalError()
            }
        } else {
            fatalError("Failed to make functions")
        }
        setupInputViews()
    }
    
    private func setupInputViews() {
        let cRealSlider = SliderInput(name: "C Real", minValue: -2, currentValue: 0, maxValue: 2)
        let cImaginarySlider = SliderInput(name: "C Imaginary", minValue: -2, currentValue: 0, maxValue: 2)

        let zoomSlider = SliderInput(name: "Zoom", minValue: 1, currentValue: 10, maxValue: 10000)

        let originX = SliderInput(name: "Origin X", minValue: -9999, currentValue: 0, maxValue: 9999)
        let originY = SliderInput(name: "Origin Y", minValue: -9999, currentValue: 0, maxValue: 9999)

        let colorScalingFactor = SliderInput(name: "scaling Factor", minValue: 0.1, currentValue: 1, maxValue: 100)
        
//        let colorList = ListInput<ColorInput>(inputs: (0..<2).map {
//            ColorInput(name: "Color \($0)", defaultColor: <#T##NSColor#>)
//        }, name: "Coloring")

        let colorList = ListInput<ColorInput>(inputs: [
            ColorInput(name: "Color 1", defaultColor: NSColor(red: 1, green: 1, blue: 1, alpha: 1)),
            ColorInput(name: "Color 2", defaultColor: NSColor(red: 0, green: 0, blue: 0, alpha: 1))
        ], name: "Coloring")
        
        renderSpecificInputs = [cRealSlider, cImaginarySlider,
                          zoomSlider,
                          originX,originY,
                          colorScalingFactor,
                          colorList]
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        guard let colorInputs = self.renderSpecificInputs?[6] as? ListInput<ColorInput> else { return }
        let colors = colorInputs.output.map { $0.cgColor.toVector() }
        let colorBuffers = device.makeBuffer(bytes: colors, length: MemoryLayout<SIMD3<Float>>.stride * colors.count, options: .storageModeManaged)
        if state == .juliaSet {
            let juliaEncoder = commandBuffer.makeComputeCommandEncoder()
            juliaEncoder?.setComputePipelineState(juliaPipeline)
            juliaEncoder?.setBytes([SIMD2<Int32>(Int32(size.width),Int32(size.height))],
                                   length: MemoryLayout<SIMD2<Int32>>.stride,
                                   index: 0)
            juliaEncoder?.setBytes([SIMD2<Int32>(Int32(maxRenderSize.width),Int32(maxRenderSize.height))],
                                   length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
            juliaEncoder?.setBytes([frame], length: MemoryLayout<Int32>.stride, index: 2)
            juliaEncoder?.setBytes([origin], length: MemoryLayout<SIMD2<Float>>.stride, index: 3)
            juliaEncoder?.setBytes([c], length: MemoryLayout<SIMD2<Float>>.stride, index: 4)
            juliaEncoder?.setBytes([zoom], length: MemoryLayout<Float>.stride, index: 5)
            juliaEncoder?.setBytes([scalingFactor], length: MemoryLayout<Float>.stride, index: 6)
            juliaEncoder?.setBuffer(colorBuffers, offset: 0, index: 7)
            juliaEncoder?.setBytes([Int32(colors.count)], length: MemoryLayout<Int32>.stride, index: 8)
            juliaEncoder?.setTexture(outputImage, index: 0)
            juliaEncoder?.dispatchThreadgroups(getCappedGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            juliaEncoder?.endEncoding()
        }
        
        frame += 1
        
    }
}

extension NSColor {
    convenience init(color: SIMD3<Float>) {
        self.init(red: CGFloat(color.x),
                  green: CGFloat(color.y),
                  blue: CGFloat(color.z),
                  alpha: 1)
    }
    func toVector() -> SIMD3<Float> {
        return SIMD3<Float>(Float(redComponent),
                            Float(greenComponent),
                            Float(blueComponent))
    }
}

extension CGColor {
    func toVector() -> SIMD3<Float> {
        if numberOfComponents >= 3 {
            guard let components = components else {
                return SIMD3<Float>(1,1,1)
            }
            return SIMD3<Float>(Float(components[0]),Float(components[1]),Float(components[2]))
        }
        return SIMD3<Float>(1,1,1)
    }
}
