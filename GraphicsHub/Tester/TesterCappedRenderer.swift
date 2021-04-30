//
//  TesterCappedRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/29/21.
//

import MetalKit

class TesterCappedRenderer: SinglyCappedRenderer {
    
    override var resizeable: Bool { true }
    
    var tidComputePipeline: MTLComputePipelineState!
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size)
        if let tidFunction = createFunctions(names: "testerSinglyCapped")[0] {
            do {
                tidComputePipeline = try device.makeComputePipelineState(function: tidFunction)
            } catch {
                print(error)
                fatalError()
            }
        }else {
            fatalError("No tester function made")
        }
    }
    
    override func graphicsPipeline(commandBuffer: MTLCommandBuffer, view: MTKView) {
//        dispatchComputeEncoder(commandBuffer: commandBuffer,
//                               computePipelineState: tidComputePipeline,
//                               buffers: [],
//                               bytes: [([Int32(frame)] as! UnsafeRawPointer, MemoryLayout<Int32>.stride, 0),
//                                       ([SIMD2<Int32>(Int32(size.width), Int32(size.height))]  as! UnsafeRawPointer, MemoryLayout<SIMD2<Int32>>.stride, 1),
//                                       ([SIMD2<Int32>(Int32(maxRenderSize!.width),Int32(maxRenderSize!.height))] as! UnsafeRawPointer, MemoryLayout<SIMD2<Int32>>.stride, 2)],
//                               textures: [self.outputImage],
//                               threadGroups: getCappedGroupSize(),
//                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        computeEncoder?.setComputePipelineState(tidComputePipeline)
        computeEncoder?.setBytes([Int32(frame)], length: MemoryLayout<Int32>.size, index: 0)
        computeEncoder?.setBytes([SIMD2<Int32>(Int32(size.width), Int32(size.height))] , length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
        computeEncoder?.setBytes([SIMD2<Int32>(Int32(maxRenderSize.width), Int32(maxRenderSize.height))] , length: MemoryLayout<SIMD2<Int32>>.stride, index: 2)
        computeEncoder?.setTexture(outputImage, index: 0)
        computeEncoder?.dispatchThreadgroups(getCappedGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        computeEncoder?.endEncoding()
        frame += 1
    }
    
}
