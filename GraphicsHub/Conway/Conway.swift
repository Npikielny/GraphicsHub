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
    }
    
    var device: MTLDevice
    
    var renderSpecificInputs: [NSView]?
    
    var size: CGSize
    
    var recordable: Bool = true
    
    var outputImage: MTLTexture!
    
    var resizeable: Bool = false
    
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
    }
    
    var cellCount: SIMD2<Int32>
//    var oldCellBuffer: MTLBuffer?
//    var cellBuffer: MTLBuffer?
    var cellBuffers = [MTLBuffer]()
    var cellPipeline: MTLComputePipelineState!
    var drawPipeline: MTLComputePipelineState!
    var copyPipeline: MTLComputePipelineState!
    
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
            drawEncoder?.setTexture(outputImage, index: 0)
            
            let colors = (inputManager as! ConwayInputManager).colors
            drawEncoder?.setBytes([colors], length: MemoryLayout<SIMD3<Float>>.stride * colors.count, index: 3)
            drawEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            drawEncoder?.endEncoding()
            cellBuffers.swapAt(0, 1)
        }
    }
    
    var renderPipelineState: MTLRenderPipelineState?
    
    required init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.size = size
        self.cellCount = SIMD2<Int32>(512,512)
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
    }
    
    enum State: Int32 {
        case Dead = 0
        case Alive = 1
        case Old = 2
    }
    
}

class ConwayInputManager: BasicInputManager {
    var colors: [SIMD3<Float>] {
        (getInput(1) as! ListInput<ColorPickerInput>).output.map { $0.toVector() }
    }
    override init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        var inputs = renderSpecificInputs
        let colorTester = ColorInput(name: "Test", defaultColor: SIMD4<Float>(1,1,0,1))
        inputs.insert(colorTester, at: 0)
        let colorList = ListInput<ColorPickerInput>(name: "Colors", inputs: [
            ColorPickerInput(name: "Background", defaultColor: NSColor(red: 0, green: 0, blue: 0, alpha: 1)),
            ColorPickerInput(name: "New Cell", defaultColor: NSColor(red: 1, green: 0, blue: 0, alpha: 1)),
            ColorPickerInput(name: "Old Cell", defaultColor: NSColor(red: 1, green: 1, blue: 1, alpha: 1))
        
        ])
        inputs.insert(colorList, at: 1)
        super.init(renderSpecificInputs: inputs, imageSize: imageSize)
    }
    
}
