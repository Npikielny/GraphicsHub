//
//  BoidRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/16/21.
//

import MetalKit

class BoidRenderer: RayMarchingRenderer {
    
    private var boidCount: Int
    private var boidBuffer: MTLBuffer!
    
    private var boidComputePipeline: MTLComputePipelineState!
    
    required init(device: MTLDevice, size: CGSize) {
        var boids = [Boid]()
        self.boidCount = 50
        for _ in 0..<boidCount {
            boids.append(Boid(heading: SIMD3<Float>(Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5)),
                              position: SIMD3<Float>(Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5)) * 100))
        }
        self.boidBuffer = device.makeBuffer(bytes: boids, length: MemoryLayout<Boid>.stride * boidCount, options: .storageModeManaged)
        super.init(device: device, size: size, objects: boids.map({
            Object.sphere(materialType: .randomNormal, position: $0.position, size: SIMD3<Float>(repeating: 0.2))
        }))
        name = "Boids Renderer"
        
        let functions = createFunctions(names: "boid")
        if let boidFunction = functions[0] {
            do {
                boidComputePipeline = try device.makeComputePipelineState(function: boidFunction)
            } catch {
                print(error)
                fatalError()
            }
        }
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        <#code#>
    }
    
    struct Boid {
        var heading: SIMD3<Float>
        var position: SIMD3<Float>
    }
}
