//
//  CustomPathRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/27/21.
//

import MetalKit

class CustomPathRenderer: HighFidelityRayRenderer {
    
    var skyTexture: MTLTexture!
    var skySize: SIMD2<Int32>!
        
    var rayPipeline: MTLComputePipelineState!
    var floatPipeline: MTLComputePipelineState!
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device,
                   size: size,
                   objects: SceneManager.generate(objectCount: 1000,
                                                  objectTypes: [.Box, .Sphere, .Triangle],
                                                  generationType: .procedural,
                                                  positionType: .radial,
                                                  collisionType: [.grounded, .distinct],
                                                  objectSizeRange: (SIMD3<Float>(repeating: 0.1), SIMD3<Float>(repeating: 2)),
                                                  objectPositionRange: (SIMD3<Float>(0, 0, 0), SIMD3<Float>(10, Float.pi * 2, 0)),
                                                  materialType: .solidLit),
                   inputManager: HighFidelityRayInputManager(size: size),
                   imageCount: 2)
        name = "Vanilla Path Trace Renderer"
        let function = createFunctions("pathTrace", "floatObjects")
        if let rayFunction = function[0] {
            do {
                rayPipeline = try device.makeComputePipelineState(function: rayFunction)
                skyTexture = try loadTexture(name: "rural_landscape_4k")
                skySize = SIMD2<Int32>(Int32(skyTexture.width), Int32(skyTexture.height))
                floatPipeline = try device.makeComputePipelineState(function: function[1]!)
            } catch {
                print(error)
                fatalError()
            }
        }
//        renderPipelineState = nil
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
//        if filledRender {
//            dispatchComputeEncoder(commandBuffer: commandBuffer,
//                                   computePipeline: floatPipeline,
//                                   buffers: [objectBuffer],
//                                   bytes: { encoder, offset in
//                                    encoder?.setBytes([Int32(self.frame)], length: MemoryLayout<Int32>.stride, index: offset)
//                                   },
//                                   textures: [],
//                                   threadGroups: MTLSize(width: (objects.count + 7) / 8, height: 1, depth: 1),
//                                   threadGroupSize: MTLSize(width: 8, height: 1, depth: 1))
//        }
        
        let rayEncoder = commandBuffer.makeComputeCommandEncoder()
        rayEncoder?.setComputePipelineState(rayPipeline)
        
        rayEncoder?.setBuffer(objectBuffer, offset: 0, index: 0)
        rayEncoder?.setBytes([Int32(objects.count)], length: MemoryLayout<Int32>.stride, index: 1)
        rayEncoder?.setBytes([camera.makeModelMatrix(), camera.makeProjectionMatrix()], length: MemoryLayout<float4x4>.stride * 2, index: 2)
        rayEncoder?.setBytes([SIMD2<Int32>(Int32(size.width), Int32(size.height))], length: MemoryLayout<SIMD2<Int32>>.stride, index: 3)
        rayEncoder?.setBytes([SIMD2<Int32>(Int32(computeSize.width),Int32(computeSize.height))], length: MemoryLayout<SIMD2<Int32>>.stride, index: 4)
        rayEncoder?.setBytes([skySize], length: MemoryLayout<SIMD2<Int32>>.stride, index: 5)
        rayEncoder?.setBytes([lightDirection], length: MemoryLayout<SIMD4<Float>>.stride, index: 6)
        rayEncoder?.setBytes([SIMD2<Float>(Float.random(in: -0.5...0.5),Float.random(in: -0.5...0.5))], length: MemoryLayout<SIMD2<Float>>.stride, index: 7)
        rayEncoder?.setBytes([Int32(intermediateFrame)], length: MemoryLayout<Int32>.stride, index: 8)
        rayEncoder?.setBytes([Int32(renderPasses)], length: MemoryLayout<Int32>.stride, index: 9)
        rayEncoder?.setBytes([Int32(renderPassesPerFrame)], length: MemoryLayout<Int32>.stride, index: 10)
        rayEncoder?.setBytes([Int32(frame)], length: MemoryLayout<Int32>.stride, index: 11)
        rayEncoder?.setBytes([skyIntensity], length: MemoryLayout<Int32>.stride, index: 12)
        rayEncoder?.setTexture(skyTexture, index: 0)
        rayEncoder?.setTexture(images[0], index: 1)
        
        rayEncoder?.dispatchThreadgroups(getCappedGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        rayEncoder?.endEncoding()
        super.draw(commandBuffer: commandBuffer, view: view)
    }
}
