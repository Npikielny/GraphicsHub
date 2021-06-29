//
//  Conway.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/29/21.
//

import MetalKit

class ConwayRenderer: SimpleRenderer {
    
    
    var cellBuffers = [MTLBuffer]()
    var colorBuffer: MTLBuffer!
    
    var cellPipeline: MTLComputePipelineState!
    var drawPipeline: MTLComputePipelineState!
    var copyPipeline: MTLComputePipelineState!
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: ConwayInputManager(imageSize: size), name: "Conway's Game of Life")
        let functions = createFunctions(names: "conwayCalculate", "conwayDraw", "conwayCopy")
        do {
            cellPipeline = try device.makeComputePipelineState(function: functions[0]!)
            drawPipeline = try device.makeComputePipelineState(function: functions[1]!)
            copyPipeline = try device.makeComputePipelineState(function: functions[2]!)
            recordPipeline = try getRecordPipeline()
        } catch {
            print(error)
            fatalError()
        }
        colorBuffer = device.makeBuffer(length: MemoryLayout<SIMD4<Float>>.stride * 4, options: .storageModeManaged)
        resetCells()
    }
    
    override func synchronizeInputs() {
        super.synchronizeInputs()
        if let inputManager = inputManager as? ConwayInputManager {
            if inputManager.colorsDidChange {
                memcpy(colorBuffer.contents(), inputManager.colors, colorBuffer.length)
                colorBuffer.didModifyRange(0..<colorBuffer.length)
            }
            if inputManager.cellCountDidChange {
                resetCells()
            }
        }
        updateAllInputs()
    }
    
    override func drawableSizeDidChange(size: CGSize) {
        super.drawableSizeDidChange(size: size)
        resetCells()
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        if cellBuffers.count == 2 {
            guard let inputManager = inputManager as? ConwayInputManager else { return }
            let cellCount = SIMD2<Int32>(Int32(inputManager.cellSize.width), Int32(inputManager.cellSize.height))
            for _ in 0..<inputManager.iterationsPerFrame {
                let cellEncoder = commandBuffer.makeComputeCommandEncoder()
                cellEncoder?.setComputePipelineState(cellPipeline)
                cellEncoder?.setBytes([cellCount], length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
                cellEncoder?.setBuffer(cellBuffers[0], offset: 0, index: 1)
                cellEncoder?.setBuffer(cellBuffers[1], offset: 0, index: 2)
                cellEncoder?.dispatchThreadgroups(getThreadGroupSize(size: cellCount, ThreadSize: MTLSize(width: 8, height: 8, depth: 1)), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
                cellEncoder?.endEncoding()
                
                cellBuffers.swapAt(0, 1)
            }
            let drawEncoder = commandBuffer.makeComputeCommandEncoder()
            drawEncoder?.setComputePipelineState(drawPipeline)
            drawEncoder?.setBytes([SIMD2<Int32>(Int32(size.width), Int32(size.height))],
                                  length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
            drawEncoder?.setBytes([cellCount], length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
            drawEncoder?.setBuffer(cellBuffers[1], offset: 0, index: 2)
            drawEncoder?.setBuffer(colorBuffer, offset: 0, index: 3)
            drawEncoder?.setBytes([inputManager.withOutline], length: MemoryLayout<Bool>.stride, index: 4)
            
            drawEncoder?.setTexture(outputImage, index: 0)
            
            drawEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            drawEncoder?.endEncoding()
        }
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
    func resetCells() {
        cellBuffers = []
        
        let inputManager = self.inputManager as! ConwayInputManager
        let cellSize = inputManager.cellSize
        let cellCount = Int(cellSize.width * cellSize.height)
        
        var values = [Int32]()
        for _ in 0..<cellCount {
            values.append(Int32.random(in: -100 + Int32(inputManager.spawnProbability)...1))
        }
        cellBuffers.append(device.makeBuffer(bytes: values, length: MemoryLayout<Int32>.stride * values.count, options: .storageModeManaged)!)
        cellBuffers.append(device.makeBuffer(length: MemoryLayout<Int32>.stride * cellCount, options: .storageModeManaged)!)
        
        frame = 0
    }
    
    enum State: Int32 {
        case Dead = 0
        case Alive = 1
        case Old = 2
    }
    
}

class ConwayInputManager: BasicInputManager {
    var cellSize: CGSize { (getInput(0) as! SizeInput).output }
    var cellCountDidChange: Bool { (getInput(0) as! SizeInput).didChange }
    
    var spawnProbability: Double { (getInput(1) as! SliderInput).output }
    var withOutline: Bool { (getInput(2) as! StateInput).output }
    
    var iterationsPerFrame: Int { Int((getInput(3) as! SliderInput).output) }
    
    var colors: [SIMD4<Float>] { (getInput(4) as! ListInput<NSColor, ColorPickerInput>).output.map { $0.toVector() } }
    var colorsDidChange: Bool { (getInput(4) as! ListInput<NSColor, ColorPickerInput>).didChange }
    
    override init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        let cellCount = SizeInput(name: "Cells", prefix: "Cell", minSize: CGSize(width: 50, height: 50), size: CGSize(width: 512, height: 512), maxSize: CGSize(width: 2048, height: 2048))
        let spawnProbability = SliderInput(name: "Spawn Probability", minValue: 1, currentValue: 30, maxValue: 100, tickMarks: 100, animateable: true)
        let outlineInput = StateInput(name: "Draw Outlines")
        let iterationsPerFrame = SliderInput(name: "Iterations Per Frame", minValue: 1, currentValue: 1, maxValue: 10, tickMarks: 10)
        let colorList = ListInput<NSColor, ColorPickerInput>(name: "Colors", inputs: [
            ColorPickerInput(name: "Background", defaultColor: NSColor(red: 0, green: 0, blue: 0, alpha: 1), animateable: false),
            ColorPickerInput(name: "New Cell", defaultColor: NSColor(red: 1, green: 0, blue: 0, alpha: 1), animateable: false),
            ColorPickerInput(name: "Old Cell", defaultColor: NSColor(red: 0, green: 0, blue: 1, alpha: 1), animateable: false),
            ColorPickerInput(name: "Outline", defaultColor: NSColor(red: 1, green: 1, blue: 1, alpha: 1), animateable: false),
        ])
        super.init(renderSpecificInputs: [cellCount,
                                          spawnProbability,
                                          outlineInput,
                                          iterationsPerFrame,
                                          colorList] + renderSpecificInputs, imageSize: imageSize)
    }
    
}
