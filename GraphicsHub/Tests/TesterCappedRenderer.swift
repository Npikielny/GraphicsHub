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
    var seed: Int32 = Int32.random(in: Int32.min...Int32.max)
    var requiredFrames: Int {
        let shift: (Int, Int) = (Int(ceil(size.width / maxRenderSize.width)),
                                 Int(ceil(size.height / maxRenderSize.height)))
        return shift.0 * shift.1;
    }
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        if (frame % requiredFrames == 0) {
            seed = Int32.random(in: Int32.min...Int32.max)
        }
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        computeEncoder?.setComputePipelineState(tidComputePipeline)
        computeEncoder?.setBytes([Int32(frame)], length: MemoryLayout<Int32>.size, index: 0)
        computeEncoder?.setBytes([SIMD2<Int32>(Int32(size.width), Int32(size.height))] , length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
        computeEncoder?.setBytes([SIMD2<Int32>(Int32(maxRenderSize.width), Int32(maxRenderSize.height))] , length: MemoryLayout<SIMD2<Int32>>.stride, index: 2)
        computeEncoder?.setBytes([seed] , length: MemoryLayout<Int32>.stride, index: 3)
        computeEncoder?.setTexture(outputImage, index: 0)
        computeEncoder?.dispatchThreadgroups(getCappedGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        computeEncoder?.endEncoding()
        super.draw(commandBuffer: commandBuffer, view: view)
        
    }
    
}
