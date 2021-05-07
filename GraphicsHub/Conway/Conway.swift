//
//  Conway.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/29/21.
//

import MetalKit

class ConwayRenderer: Renderer {
    
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
        self.oldCellBuffer = device.makeBuffer(length: MemoryLayout<Int32>.stride * Int(cellCount.x * cellCount.y), options: .storageModeManaged)
        self.cellBuffer = device.makeBuffer(length: MemoryLayout<Int32>.stride * Int(cellCount.x * cellCount.y), options: .storageModeManaged)
        
        var values = [Int32]()
        for _ in 0..<Int(cellCount.x * cellCount.y) {
            values.append(Int32.random(in: -10...1))
        }
        
        memcpy(oldCellBuffer!.contents(), values, MemoryLayout<Int32>.stride * Int(cellCount.x * cellCount.y))
        oldCellBuffer!.didModifyRange(0..<oldCellBuffer!.length)
    }
    
    var cellCount: SIMD2<Int32>
    var oldCellBuffer: MTLBuffer?
    var cellBuffer: MTLBuffer?
    var cellPipeline: MTLComputePipelineState!
    var drawPipeline: MTLComputePipelineState!
    var copyPipeline: MTLComputePipelineState!
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        if let buffer = cellBuffer, let oldBuffer = oldCellBuffer {
            let cellEncoder = commandBuffer.makeComputeCommandEncoder()
            cellEncoder?.setComputePipelineState(cellPipeline)
            cellEncoder?.setBytes([cellCount], length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
            cellEncoder?.setBuffer(buffer, offset: 0, index: 1)
            cellEncoder?.setBuffer(oldBuffer, offset: 0, index: 2)
            cellEncoder?.dispatchThreadgroups(getThreadGroupSize(size: cellCount, ThreadSize: MTLSize(width: 8, height: 8, depth: 1)), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            cellEncoder?.endEncoding()
            
            let drawEncoder = commandBuffer.makeComputeCommandEncoder()
            drawEncoder?.setComputePipelineState(drawPipeline)
            drawEncoder?.setBytes([SIMD2<Int32>(Int32(size.width), Int32(size.height))],
                                  length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
            drawEncoder?.setBytes([cellCount], length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
            drawEncoder?.setBuffer(buffer, offset: 0, index: 2)
            drawEncoder?.setTexture(outputImage, index: 0)
            drawEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            drawEncoder?.endEncoding()
            
            let copyEncoder = commandBuffer.makeComputeCommandEncoder()
            copyEncoder?.setComputePipelineState(copyPipeline)
            copyEncoder?.setBytes([cellCount], length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
            copyEncoder?.setBuffer(buffer, offset: 0, index: 1)
            copyEncoder?.setBuffer(oldBuffer, offset: 0, index: 2)
            copyEncoder?.dispatchThreadgroups(getThreadGroupSize(size: cellCount, ThreadSize: MTLSize(width: 1, height: 1, depth: 1)), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
            copyEncoder?.endEncoding()
        }
    }
    
    var renderPipelineState: MTLRenderPipelineState?
    
    required init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.size = size
        self.cellCount = SIMD2<Int32>(512,512)
        self.inputManager = BasicInputManager(imageSize: size)
        let functions = createFunctions(names: "conwayCalculate", "conwayDraw", "conwayCopy")
        do {
            self.cellPipeline = try device.makeComputePipelineState(function: functions[0]!)
            self.drawPipeline = try device.makeComputePipelineState(function: functions[1]!)
            self.copyPipeline = try device.makeComputePipelineState(function: functions[2]!)
            self.recordPipeline = try getRecordPipeline()
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
