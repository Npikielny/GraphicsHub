//
//  ComplexRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import MetalKit

class ComplexRenderer: SinglyCappedRenderer {
    var juliaPipeline: MTLComputePipelineState!
    var mandelbrotPipeline: MTLComputePipelineState!
    
    func randomColor() -> SIMD3<Float> {
        return SIMD3<Float>(Float.random(in: 0...1),
                            Float.random(in: 0...1),
                            Float.random(in: 0...1))
    }
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: ComplexInputManager(size: size))
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
        name = "ComplexRenderer"
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        guard let inputManager = inputManager as? ComplexInputManager else { return }
        if inputManager.state == .juliaSet {
            let juliaEncoder = commandBuffer.makeComputeCommandEncoder()
            juliaEncoder?.setComputePipelineState(juliaPipeline)
            juliaEncoder?.setBytes([SIMD2<Int32>(Int32(size.width),Int32(size.height))],
                                   length: MemoryLayout<SIMD2<Int32>>.stride,
                                   index: 0)
            juliaEncoder?.setBytes([SIMD2<Int32>(Int32(maxRenderSize.width),Int32(maxRenderSize.height))],
                                   length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
            juliaEncoder?.setBytes([frame], length: MemoryLayout<Int32>.stride, index: 2)
            juliaEncoder?.setBytes([inputManager.origin.toVector()], length: MemoryLayout<SIMD2<Float>>.stride, index: 3)
            juliaEncoder?.setBytes([inputManager.c.toInverseVector()], length: MemoryLayout<SIMD2<Float>>.stride, index: 4)
            juliaEncoder?.setBytes([inputManager.zoom], length: MemoryLayout<Float>.stride, index: 5)
            juliaEncoder?.setBytes([inputManager.scalingFactor], length: MemoryLayout<Float>.stride, index: 6)
            let colors = inputManager.colors
            juliaEncoder?.setBytes(colors, length: colors.count * MemoryLayout<SIMD3<Float>>.stride, index: 7)
            juliaEncoder?.setBytes([Int32(colors.count)], length: MemoryLayout<Int32>.stride, index: 8)
            juliaEncoder?.setTexture(outputImage, index: 0)
            juliaEncoder?.dispatchThreadgroups(getCappedGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            juliaEncoder?.endEncoding()
        }
        super.draw(commandBuffer: commandBuffer, view: view)
    }
}

class ComplexInputManager: CappedInputManager {
    var state: State = .juliaSet
    enum State {
        case juliaSet
        case mandelbrotSet
    }
    
    var c: CGPoint {
        get {
            (getInput(0) as! PointInput).output
        }
        set {
            let c = getInput(0) as! PointInput
            c.x = newValue.x
            c.y = newValue.y
        }
    }
    var zoom: Float {
        get {
           Float((getInput(1) as! SliderInput).output)
        }
        set {
            (getInput(1) as! SliderInput).setValue(value: Double(newValue))
        }
    }
    var origin: CGPoint {
        get {
            (getInput(2) as! PointInput).output
        }
        set {
            let output = getInput(2) as! PointInput
            output.x = newValue.x
            output.y = newValue.y
        }
    }
    var scalingFactor: Float {
        get {
            Float((getInput(3) as! SliderInput).output)
        }
        set {
            (getInput(3) as! SliderInput).setValue(value: Double(newValue))
        }
    }
    var colors: [SIMD3<Float>] {
        (getInput(4) as! ListInput<NSColor, ColorPickerInput>).output.map { $0.toVector() }
    }
    convenience init(size: CGSize) {
        let c = PointInput(name: "C", xName: "C Imaginary", yName: "C Real", origin: CGPoint(x: 0, y: 0), size: CGSize(width: 4, height: 4))
        let zoom = SliderInput(name: "Zoom", minValue: 1, currentValue: 20, maxValue: 10000)
        let origin = PointInput(name: "Origin", origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1000000, height: 1000000))
        let scalingFactor = SliderInput(name: "Scaling Factor", minValue: 0.1, currentValue: 1, maxValue: 10)
        let colorList = ListInput<NSColor, ColorPickerInput>(name: "Colors", inputs: [
            ColorPickerInput(name: "Color 1", defaultColor: NSColor(red: 1, green: 1, blue: 1, alpha: 1)),
            ColorPickerInput(name: "Color 2", defaultColor: NSColor(red: 0, green: 0, blue: 0, alpha: 1)),
        ])
        self.init(renderSpecificInputs: [c,
                                         zoom,
                                         origin,
                                         scalingFactor,
                                         colorList
        ], imageSize: size)
    }
    override func keyDown(event: NSEvent) {
        if event.charactersIgnoringModifiers == " " {
            if scrollType == .origin {
                scrollType = .c
            } else {
                scrollType = .origin
            }
        }
    }
    override func mouseDragged(event: NSEvent) {
        if scrollType == .c {
            c = CGPoint(x: c.x - event.deltaX / CGFloat(zoom), y: c.y + event.deltaY / CGFloat(zoom))
        } else {
            origin = CGPoint(x: origin.x - event.deltaX / CGFloat(zoom), y: origin.y + event.deltaY / CGFloat(zoom))
        }
    }
    override func scrollWheel(event: NSEvent) {
        zoom += Float(event.scrollingDeltaX + event.scrollingDeltaY)
    }
    private var scrollType: ScrollType = .origin
    enum ScrollType {
        case origin
        case c
    }
    private var setType: SetType = .juliaSet
    enum SetType {
        case mandelBrot
        case juliaSet
    }
}
