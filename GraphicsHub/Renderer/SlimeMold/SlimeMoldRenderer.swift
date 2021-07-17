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
    var drawPipeline: MTLComputePipelineState!
    
    var moldBuffer: MTLBuffer!
    var moldCount: Int = 1000000
    
    var previousBuffer: MTLBuffer!
    var trailBuffer: MTLBuffer!
    
    var speciesCount: Int = 3
    
    var bufferCount: Int { speciesCount * Int(size.width * size.height) }
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: SlimeMoldInputManager(imageSize: size), name: "Slime Mold Simulation")
        do {
            let functions = createFunctions(names: "slimeMoldCalculate", "slimeMoldAverage", "drawSlime")
            calculatePipeline = try device.makeComputePipelineState(function: functions[0]!)
            averagePipeline = try device.makeComputePipelineState(function: functions[1]!)
            drawPipeline = try device.makeComputePipelineState(function: functions[2]!)
        } catch {
            print(error)
            fatalError()
        }
        setupMoldBuffer()
//        lastImage = createTexture(size: size)
    }
    
    func setupMoldBuffer() {
        var molds = [Node]()
        for _ in 0..<moldCount {
            let species = Int32(Int.random(in: 0...speciesCount-1))
            let theta = Float.random(in: 0...Float.pi * 2)
            let radius = Float.random(in: 0...250)
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
        createTrailMaps()
    }
    
    func createTrailMaps() {
        trailBuffer = device.makeBuffer(bytes: Array(repeating: Float(0), count: bufferCount), length: MemoryLayout<Float>.stride * bufferCount, options: .storageModeManaged)
        previousBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride * bufferCount, options: .storageModePrivate)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        guard let inputManager = inputManager as? SlimeMoldInputManager else { return }
        
        let calculateEncoder = commandBuffer.makeComputeCommandEncoder()
        calculateEncoder?.setComputePipelineState(calculatePipeline)
        calculateEncoder?.setBuffer(moldBuffer, offset: 0, index: 0)
        calculateEncoder?.setBytes([Int32(moldCount)], length: MemoryLayout<Int32>.stride, index: 1)
        calculateEncoder?.setBytes([size.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 2)
        calculateEncoder?.setBytes([inputManager.speed], length: MemoryLayout<Float>.stride, index: 3)
        calculateEncoder?.setBytes([inputManager.attraction], length: MemoryLayout<Float>.stride, index: 4)
        calculateEncoder?.setBytes([inputManager.repulsion], length: MemoryLayout<Float>.stride, index: 5)
        calculateEncoder?.setBytes([inputManager.turnForce], length: MemoryLayout<Float>.stride, index: 6)
        calculateEncoder?.setBytes([frame], length: MemoryLayout<Int32>.stride, index: 7)
        calculateEncoder?.setBytes([Int32(speciesCount)], length: MemoryLayout<Int32>.stride, index: 8)
        calculateEncoder?.setBuffer(trailBuffer, offset: 0, index: 9)
        calculateEncoder?.dispatchThreadgroups(MTLSize(width: (moldCount + 7) / 8, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 8, height: 1, depth: 1))
        calculateEncoder?.endEncoding()

        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: trailBuffer, sourceOffset: 0, to: previousBuffer, destinationOffset: 0, size: MemoryLayout<Float>.stride * bufferCount)
        blitEncoder?.endEncoding()

        let colors: [SIMD4<Float>] = inputManager.colors.map({ $0.toVector() })
        
        let averageEncoder = commandBuffer.makeComputeCommandEncoder()
        averageEncoder?.setComputePipelineState(averagePipeline)
        averageEncoder?.setBytes([size.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
        averageEncoder?.setBytes([Int32(inputManager.diffusionSize)], length: MemoryLayout<Int32>.stride, index: 1)
        averageEncoder?.setBytes([inputManager.diffusionRate], length: MemoryLayout<Float>.stride, index: 2)
        averageEncoder?.setBytes([Int32(speciesCount)], length: MemoryLayout<Int32>.stride, index: 3)
        averageEncoder?.setBytes(colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 4)
        averageEncoder?.setBuffer(previousBuffer, offset: 0, index: 5)
        averageEncoder?.setBuffer(trailBuffer, offset: 0, index: 6)
        averageEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        averageEncoder?.endEncoding()
        
        let drawSlimeEncoder = commandBuffer.makeComputeCommandEncoder()
        drawSlimeEncoder?.setComputePipelineState(drawPipeline)
        drawSlimeEncoder?.setBytes([Int32(speciesCount)], length: MemoryLayout<Int32>.stride, index: 0)
        drawSlimeEncoder?.setBuffer(trailBuffer, offset: 0, index: 1)
        drawSlimeEncoder?.setBytes(colors, length: MemoryLayout<SIMD4<Float>>.stride * colors.count, index: 2)
        drawSlimeEncoder?.setBytes([size.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 3)
        drawSlimeEncoder?.setTexture(image, index: 0)
        drawSlimeEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        drawSlimeEncoder?.endEncoding()
        
        checkSpecies(commandBuffer: commandBuffer)
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
    private func checkSpecies(commandBuffer: MTLCommandBuffer) {
        let inputManager = inputManager as! SlimeMoldInputManager
        let colorCount = inputManager.colors.count
        if speciesCount < colorCount {
            
            let synchronizationEncoder = commandBuffer.makeBlitCommandEncoder()
            synchronizationEncoder?.synchronize(resource: moldBuffer)
            synchronizationEncoder?.endEncoding()
            
            let contents = moldBuffer.contents().bindMemory(to: Node.self, capacity: moldCount)
            for i in 0...moldCount {
                if Int.random(in: 0...speciesCount - 1) == speciesCount - 1 {
                    contents[i].species = Int32(speciesCount - 1)
                }
            }
            memcpy(moldBuffer.contents(), contents, moldBuffer.length)
            moldBuffer.didModifyRange(0..<moldBuffer.length)
        } else if speciesCount > colorCount {
            moldCount = moldCount * colorCount / speciesCount
            var molds = [Node]()
            for _ in 0..<moldCount {
                let species = Int32(Int.random(in: 0...speciesCount - 2))
                let theta = Float.random(in: 0...Float.pi * 2)
                let radius = Float.random(in: 0...750)
                molds.append(Node(position: SIMD2<Float>(cos(theta), sin(theta)) * radius,
                                  direction: Float.random(in: 0...Float.pi * 2),
                                  species: species))
                
            }
            moldBuffer = device.makeBuffer(bytes: molds, length: MemoryLayout<Node>.stride * moldCount, options: .storageModeManaged)
        }
        if speciesCount != colorCount {
            speciesCount = colorCount
            createTrailMaps()
        }
    }
}

class SlimeMoldInputManager: BasicInputManager {
    
    var speed: Float {
        Float((getInput(0) as! SliderInput).output)
    }
    
    var diffusionSize: Int {
        Int((getInput(1) as! SliderInput).output)
    }
    
    var diffusionRate: Float {
        Float((getInput(2) as! SliderInput).output)
    }
    
    var attraction: Float {
        get { Float((getInput(3) as! SliderInput).output) }
        set { (getInput(3) as! SliderInput).setValue(value: Double(newValue)) }
    }
    
    var repulsion: Float {
        get { Float((getInput(4) as! SliderInput).output) }
        set { (getInput(4) as! SliderInput).setValue(value: Double(newValue)) }
    }
    
    var turnForce: Float { Float((getInput(5) as! SliderInput).output) }
    
    var colors: [NSColor] {
//        (getInput(6) as! ListInput<NSColor, ColorPickerInput>).output
        ([
            (getInput(6) as! ColorPickerInput).output,
            (getInput(7) as! ColorPickerInput).output,
            (getInput(8) as! ColorPickerInput).output,
        ])
    }
    
    override init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        let speed = SliderInput(name: "Speed", minValue: 0, currentValue: 1, maxValue: 10)
        let diffusionSize = SliderInput(name: "Diffusion Size", minValue: 1, currentValue: 1, maxValue: 5, tickMarks: 10)
        let diffusionRate = SliderInput(name: "Diffusion Rate", minValue: 0.0001, currentValue: 0.1, maxValue: 1)
        let attraction = SliderInput(name: "Attraction", minValue: 0, currentValue: 0.75, maxValue: 2)
        let repulsion = SliderInput(name: "Repulsion", minValue: 0, currentValue: 1.35, maxValue: 2)
        let turnForce = SliderInput(name: "Agility", minValue: 0, currentValue: 1, maxValue: 2)
//        let colorList = ListInput<NSColor, ColorPickerInput>(name: "Colors", inputs: [
//            ColorPickerInput(name: "Species 1", defaultColor: NSColor(red: 1, green: 0, blue: 0, alpha: 1), animateable: true),
//            ColorPickerInput(name: "Species 2", defaultColor: NSColor(red: 0, green: 1, blue: 0, alpha: 1), animateable: true),
//            ColorPickerInput(name: "Species 3", defaultColor: NSColor(red: 0, green: 0, blue: 1, alpha: 1), animateable: true)
//        ])
        let species1 = ColorPickerInput(name: "Species 1", defaultColor: NSColor(red: 1, green: 0, blue: 0, alpha: 1), animateable: true)
        let species2 = ColorPickerInput(name: "Species 2", defaultColor: NSColor(red: 0, green: 1, blue: 0, alpha: 1), animateable: true)
        let species3 = ColorPickerInput(name: "Species 3", defaultColor: NSColor(red: 0, green: 0, blue: 1, alpha: 1), animateable: true)
        super.init(renderSpecificInputs: [speed, diffusionSize, diffusionRate, attraction, repulsion, turnForce, species1, species2, species3] + renderSpecificInputs, imageSize: imageSize)
    }
    
}
