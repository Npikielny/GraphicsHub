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
    private var previousBuffer: MTLBuffer!
    
    private var boidComputePipeline: MTLComputePipelineState!
    
    required init(device: MTLDevice, size: CGSize) {
        var boids = [Boid]()
        boidCount = 50
        for _ in 0..<boidCount {
            boids.append(Boid(heading: SIMD3<Float>(Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5)),
                              position: SIMD3<Float>(Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5)) * 100))
        }
        boidBuffer = device.makeBuffer(bytes: boids, length: MemoryLayout<Boid>.stride * boidCount, options: .storageModeManaged)
        previousBuffer = device.makeBuffer(length: MemoryLayout<Boid>.stride * boidCount, options: .storageModePrivate)
        super.init(device: device,
                   size: size,
                   objects: boids.map {
                    Object.sphere(materialType: .randomNormal, position: $0.position, size: SIMD3<Float>(repeating: 0.5))
                   },
                   inputManager: BoidInputManager(renderSpecificInputs: [], imageSize: size))
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
        let inputManager = inputManager as! BoidInputManager
        let copyEncoder = commandBuffer.makeBlitCommandEncoder()
        copyEncoder?.copy(from: boidBuffer, sourceOffset: 0, to: previousBuffer, destinationOffset: 0, size: boidBuffer.length)
        copyEncoder?.endEncoding()
        
        let boidEncoder = commandBuffer.makeComputeCommandEncoder()
        boidEncoder?.setComputePipelineState(boidComputePipeline)
        boidEncoder?.setBuffer(boidBuffer, offset: 0, index: 0)
        boidEncoder?.setBuffer(objectBuffer, offset: 0, index: 1)
        boidEncoder?.setBytes([Int32(boidCount)], length: MemoryLayout<Int32>.stride, index: 2)
        boidEncoder?.setBytes([inputManager.perceptionDistance], length: MemoryLayout<Float>.stride, index: 3)
        boidEncoder?.setBytes([inputManager.perceptionAngle], length: MemoryLayout<Float>.stride, index: 4)
        boidEncoder?.setBytes([inputManager.step], length: MemoryLayout<Float>.stride, index: 5)
        boidEncoder?.dispatchThreadgroups(MTLSize(width: (boidCount + 7) / 8, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 8, height: 1, depth: 1))
        boidEncoder?.endEncoding()
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
    struct Boid {
        var heading: SIMD3<Float>
        var position: SIMD3<Float>
    }
}

class BoidInputManager: RealTimeRayMarchingInputManager {
    var perceptionDistance: Float { Float((getInput(16) as! SliderInput).output) }
    var perceptionAngle: Float { Float((getInput(17) as! SliderInput).output) }
    var step: Float { Float((getInput(18) as! SliderInput).output) }
    
    override init(renderSpecificInputs: [NSView], imageSize: CGSize?) {
        let perceptionDistance = SliderInput(name: "Perception", minValue: 1, currentValue: 5, maxValue: 10)
        let perceptionAngle = SliderInput(name: "Angle", minValue: 0, currentValue: 1, maxValue: 3)
        let step = SliderInput(name: "Step Size", minValue: 0, currentValue: 0, maxValue: 10)
        super.init(renderSpecificInputs: [perceptionDistance, perceptionAngle, step] + renderSpecificInputs, imageSize: imageSize)
    }
}
