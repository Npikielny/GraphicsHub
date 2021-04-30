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
        let cReal = inputView![0] as! SliderInput
        let cImaginary = inputView![1] as! SliderInput
        return SIMD2<Float>(Float(cReal.output),Float(cImaginary.output))
    }
    var zoom: Float {
        Float((inputView![2] as! SliderInput).output)
    }
    var origin: SIMD2<Float> {
        let originX = inputView![3] as! SliderInput
        let originY = inputView![4] as! SliderInput
        return SIMD2<Float>(Float(originX.output),Float(originY.output))
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

        let originX = SliderInput(name: "Origin X", minValue: -99999, currentValue: 0, maxValue: 99999)
        let originY = SliderInput(name: "Origin Y", minValue: -99999, currentValue: 0, maxValue: 99999)

        let colorList = ListInput<ColorInput>(inputs: (0..<Int.random(in: 3...5)).map {
            ColorInput(defaultColor: NSColor(color: randomColor()), name: "Color \($0)")
        })
        
        inputView = [cRealSlider, cImaginarySlider,
                          zoomSlider,
                          originX,originY,
                          colorList]
        let partnerController = InputController(inputs: inputView!)
        let partnerWindow = NSWindow(contentViewController: partnerController)
        partnerWindow.title = "Complex Renderer Inputs"
        partnerWindow.makeKeyAndOrderFront(nil)
    }
    
    override func graphicsPipeline(commandBuffer: MTLCommandBuffer, view: MTKView) {
        let colors = (self.inputView![5] as! ListInput<ColorInput>).output.map { $0.toVector() }
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
            juliaEncoder?.setBuffer(colorBuffers, offset: 0, index: 6)
            juliaEncoder?.setBytes([Int32(colors.count)], length: MemoryLayout<Int32>.stride, index: 7)
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
