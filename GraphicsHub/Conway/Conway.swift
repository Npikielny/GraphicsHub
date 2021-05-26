//
//  Conway.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/29/21.
//

import MetalKit

class ConwayRenderer: SimpleRenderer {
    
    var url: URL?
    
    var name: String = "Conway's Game of Life"
    
    var recordPipeline: MTLComputePipelineState!
    
    var inputManager: InputManager
    func synchronizeInputs() {
        if inputManager.size() != size {
            drawableSizeDidChange(size: inputManager.size())
        }
        if let inputManager = inputManager as? ConwayInputManager {
            if inputManager.colorsDidChange {
                memcpy(colorBuffer.contents(), inputManager.colors, colorBuffer.length)
                colorBuffer.didModifyRange(0..<colorBuffer.length)
            }
        }
        updateAllInputs()
    }
    
    var device: MTLDevice
    
    var renderSpecificInputs: [NSView]?
    
    var size: CGSize
    
    var recordable: Bool = true
    
    var outputImage: MTLTexture!
    
    var resizeable: Bool = false
    
    var cellCount: SIMD2<Int32>
    var cellBuffers = [MTLBuffer]()
    var colorBuffer: MTLBuffer!
    
    var cellPipeline: MTLComputePipelineState!
    var drawPipeline: MTLComputePipelineState!
    var copyPipeline: MTLComputePipelineState!
    
    var frameStable: Bool { false }
    var frame: Int = 0
    
    func drawableSizeDidChange(size: CGSize) {
        self.size = size
        // TODO: Cell Count
        self.outputImage = createTexture(size: size)
        let cellSize = Int(cellCount.x * cellCount.y)
        
        cellBuffers = []
        
        var values = [Int32]()
        for _ in 0..<Int(cellSize) {
            values.append(Int32.random(in: -10...1))
        }
        cellBuffers.append(device.makeBuffer(bytes: values, length: MemoryLayout<Int32>.stride * values.count, options: .storageModeManaged)!)
        cellBuffers.append(device.makeBuffer(length: MemoryLayout<Int32>.stride * cellSize, options: .storageModeManaged)!)
        
        frame = 0
    }
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        if cellBuffers.count == 2 {
            let cellEncoder = commandBuffer.makeComputeCommandEncoder()
            cellEncoder?.setComputePipelineState(cellPipeline)
            cellEncoder?.setBytes([cellCount], length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
            cellEncoder?.setBuffer(cellBuffers[0], offset: 0, index: 1)
            cellEncoder?.setBuffer(cellBuffers[1], offset: 0, index: 2)
            cellEncoder?.dispatchThreadgroups(getThreadGroupSize(size: cellCount, ThreadSize: MTLSize(width: 8, height: 8, depth: 1)), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            cellEncoder?.endEncoding()
            
            let drawEncoder = commandBuffer.makeComputeCommandEncoder()
            drawEncoder?.setComputePipelineState(drawPipeline)
            drawEncoder?.setBytes([SIMD2<Int32>(Int32(size.width), Int32(size.height))],
                                  length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
            drawEncoder?.setBytes([cellCount], length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
            drawEncoder?.setBuffer(cellBuffers[1], offset: 0, index: 2)
            
            drawEncoder?.setBuffer(colorBuffer, offset: 0, index: 3)
            
            drawEncoder?.setTexture(outputImage, index: 0)
            
            drawEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            drawEncoder?.endEncoding()
            cellBuffers.swapAt(0, 1)
        }
        frame += 1
    }
    
    var renderPipelineState: MTLRenderPipelineState?
    
    required init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.size = size
        self.cellCount = SIMD2<Int32>(256,256) // TODO: Cell Count Resizing
        self.inputManager = ConwayInputManager(imageSize: size)
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
    }
    
    enum State: Int32 {
        case Dead = 0
        case Alive = 1
        case Old = 2
    }
    
}

class ConwayInputManager: BasicInputManager {
    var colors: [SIMD4<Float>] {
        (getInput(1) as! ListInput<ColorPickerInput>).output.map { $0.toVector() }
    }
    var colorsDidChange: Bool { (getInput(1) as! ListInput<ColorPickerInput>).didChange }
    override init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        var inputs = renderSpecificInputs
        let colorTester = ColorInput(name: "Test", defaultColor: SIMD4<Float>(1,1,0,1))
        inputs.insert(colorTester, at: 0)
        let colorList = ListInput<ColorPickerInput>(name: "Colors", inputs: [
            ColorPickerInput(name: "Background", defaultColor: NSColor(red: 0, green: 0, blue: 0, alpha: 1)),
            ColorPickerInput(name: "New Cell", defaultColor: NSColor(red: 1, green: 0, blue: 0, alpha: 1)),
            ColorPickerInput(name: "Old Cell", defaultColor: NSColor(red: 0, green: 0, blue: 1, alpha: 1)),
            ColorPickerInput(name: "Outline", defaultColor: NSColor(red: 1, green: 1, blue: 1, alpha: 1))
        ])
        inputs.insert(colorList, at: 1)
        super.init(renderSpecificInputs: inputs, imageSize: imageSize)
    }
    
}
