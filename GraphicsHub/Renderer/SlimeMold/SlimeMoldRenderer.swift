//
//  SlimeMoldRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/8/21.
//

import MetalKit

class SlimeMoldRenderer: Renderer {
    
    var calculatePipeline: MTLComputePipelineState!
    var averagePipeline: MTLComputePipelineState!
    
    var moldBuffer: MTLBuffer!
    var moldCount: Int = 100000
    
    var speciesCount: Int = 1
    
    var lastImage: MTLTexture!
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: SlimeMoldInputManager(imageSize: size), name: "Slime Mold Simulation")
        do {
            let functions = createFunctions(names: "slimeMoldCalculate", "slimeMoldAverage")
            calculatePipeline = try device.makeComputePipelineState(function: functions[0]!)
            averagePipeline = try device.makeComputePipelineState(function: functions[1]!)
        } catch {
            print(error)
            fatalError()
        }
        setupMoldBuffer()
        lastImage = createTexture(size: size)
    }
    
    func setupMoldBuffer() {
        var molds = [Node]()
        for _ in 0..<moldCount {
//            let theta = Float.random(in: 0...Float.pi * 2)
//            let radius = Float.random(in: 0...500)
//            molds.append(Node(position: SIMD2<Float>(cos(theta), sin(theta)) * radius,
//                              direction: Float.random(in: 0...Float.pi * 2),
//                              species: Int32(Int.random(in: 0...speciesCount - 1))))
            let species = Int32(Int.random(in: 0...speciesCount-1))
            let theta = Float.pi * 2 / Float(speciesCount) * Float(species) + Float.random(in: -1...1) * Float.pi / Float(speciesCount)
            let radius = Float.random(in: 0...750)
            molds.append(Node(position: SIMD2<Float>(cos(theta), sin(theta)) * radius,
                              direction: Float.random(in: 0...Float.pi * 2),
                              species: species))
            
        }
        moldBuffer = device.makeBuffer(bytes: molds, length: MemoryLayout<Node>.stride * moldCount, options: .storageModeManaged)
    }
    
    struct Node {
        var position: SIMD2<Float>
        var direction: Float
        var species: Int32
    }
    
    override func drawableSizeDidChange(size: CGSize) {
        super.drawableSizeDidChange(size: size)
        lastImage = createTexture(size: size)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        guard let inputManager = inputManager as? SlimeMoldInputManager else { return }
        
        let calculateEncoder = commandBuffer.makeComputeCommandEncoder()
        calculateEncoder?.setComputePipelineState(calculatePipeline)
        calculateEncoder?.setBuffer(moldBuffer, offset: 0, index: 0)
        calculateEncoder?.setBytes([Int32(moldCount)], length: MemoryLayout<Int32>.stride, index: 1)
        calculateEncoder?.setBytes([size.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 2)
        calculateEncoder?.setBytes([inputManager.attraction], length: MemoryLayout<Float>.stride, index: 3)
        let colors: [SIMD4<Float>] = inputManager.colors.map({ $0.toVector() })
        calculateEncoder?.setBytes(colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 4)
        calculateEncoder?.setBytes([inputManager.speed], length: MemoryLayout<Float>.stride, index: 5)
        calculateEncoder?.setBytes([inputManager.turnForce], length: MemoryLayout<Float>.stride, index: 6)
        calculateEncoder?.setBytes([inputManager.forwardForce], length: MemoryLayout<Float>.stride, index: 7)
        calculateEncoder?.setBytes([inputManager.detectorStrength], length: MemoryLayout<Float>.stride, index: 8)
        calculateEncoder?.setBytes([frame], length: MemoryLayout<Int32>.stride, index: 9)
        calculateEncoder?.setTexture(image, index: 0)
        calculateEncoder?.dispatchThreadgroups(MTLSize(width: (moldCount + 7) / 8, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 8, height: 1, depth: 1))
        calculateEncoder?.endEncoding()
        
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: image, to: lastImage)
        blitEncoder?.endEncoding()
        
        let averageEncoder = commandBuffer.makeComputeCommandEncoder()
        averageEncoder?.setComputePipelineState(averagePipeline)
        averageEncoder?.setBytes([size.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
        averageEncoder?.setBytes([Int32(inputManager.diffusionSize)], length: MemoryLayout<Int32>.stride, index: 1)
        averageEncoder?.setBytes([inputManager.diffusionRate], length: MemoryLayout<Float>.stride, index: 2)
        averageEncoder?.setTexture(lastImage, index: 0)
        averageEncoder?.setTexture(image, index: 1)
        averageEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        averageEncoder?.endEncoding()
        
        super.draw(commandBuffer: commandBuffer, view: view)
    }
}

class SlimeMoldInputManager: BasicInputManager {
    
    var attraction: Float {
        get {
            Float((getInput(0) as! SliderInput).output)
        }
        set {
            (getInput(0) as! SliderInput).setValue(value: Double(newValue))
        }
    }
    
    var speed: Float {
        Float((getInput(1) as! SliderInput).output)
    }
    
    var diffusionSize: Int {
        Int((getInput(2) as! SliderInput).output)
    }
    
    var diffusionRate: Float {
        Float((getInput(3) as! SliderInput).output)
    }
    
    var turnForce: Float {
        Float((getInput(4) as! SliderInput).output)
    }
    
    var forwardForce: Float {
        Float((getInput(5) as! SliderInput).output)
    }
    
    var detectorStrength: Float {
        Float((getInput(6) as! SliderInput).output)
    }
    
    var colors: [NSColor] {
        (getInput(7) as! ListInput<NSColor, ColorPickerInput>).output
    }
    
    override init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        let attraction = SliderInput(name: "Attraction", minValue: 0, currentValue: 2, maxValue: 2)
        let speed = SliderInput(name: "Speed", minValue: 0, currentValue: 0, maxValue: 10)
        let diffusionSize = SliderInput(name: "Diffusion Size", minValue: 1, currentValue: 1, maxValue: 5, tickMarks: 10)
        let diffusionRate = SliderInput(name: "Diffusion Rate", minValue: 0.0001, currentValue: 0.1, maxValue: 1)
        let turnForce = SliderInput(name: "Turn Force", minValue: 0, currentValue: 1, maxValue: 10)
        let forwardForce = SliderInput(name: "Forward Force", minValue: 0, currentValue: 1, maxValue: 5)
        let detectorStrength = SliderInput(name: "Perception", minValue: 0, currentValue: 0.25, maxValue: 1)
        let colorList = ListInput<NSColor, ColorPickerInput>(name: "Colors", inputs: [
            ColorPickerInput(name: "Species 1", defaultColor: NSColor(red: 1, green: 0, blue: 0, alpha: 1), animateable: false),
            ColorPickerInput(name: "Species 2", defaultColor: NSColor(red: 0, green: 1, blue: 0, alpha: 1), animateable: false),
            ColorPickerInput(name: "Species 3", defaultColor: NSColor(red: 0, green: 0, blue: 1, alpha: 1), animateable: false)
        ])
        colorList.customizeable = false
        super.init(renderSpecificInputs: [attraction, speed, diffusionSize, diffusionRate, turnForce, forwardForce, detectorStrength, colorList] + renderSpecificInputs, imageSize: imageSize)
    }
    
}
