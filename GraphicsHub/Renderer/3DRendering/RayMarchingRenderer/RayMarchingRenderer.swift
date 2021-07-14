//
//  RayMarchingRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/13/21.
//

import MetalKit

class RayMarchingRenderer: RayRenderer {
    
    var skyTexture: MTLTexture!
    var skySize: SIMD2<Int32>!
        
    var rayPipeline: MTLComputePipelineState!
    
    var iterations: Int {
        guard let inputManager = inputManager as? RayMarchingInputManager else { fatalError() }
        return inputManager.iterations
    }
    var maxDistance: Float {
        guard let inputManager = inputManager as? RayMarchingInputManager else  { fatalError() }
        return inputManager.maxDistance
    }
    var precision: Float {
        guard let inputManager = inputManager as? RayMarchingInputManager else  { fatalError() }
        return inputManager.precision
    }
    
    required init(device: MTLDevice, size: CGSize) {
        var locations = [SIMD3<Float>]()
        locations.append(SIMD3<Float>(10,10,5))
        locations.append(SIMD3<Float>(-10,10,5))
        for i in 0...30 {
            locations.append(SIMD3<Float>(Float(i) * 60 / 30 - 30, pow(Float(i - 15)/3, 2) - 30, 5))
        }
        var tongueLocations = [SIMD3<Float>]()
        for i in 0...20 {
            tongueLocations.append(SIMD3<Float>(Float(i) * 25 / 20 - 12.5, pow(Float(i - 10)/2, 2) - 52.5, 5))
        }
        for i in 1...7 {
            tongueLocations.append(SIMD3<Float>(0, Float(i) * 2 - 47.5, 5))
        }
        let rotationMatrix: float3x3 = Matrix<Float>.rotationMatrix(rotation: SIMD3<Float>(0, 0, 0.65))
        locations.append(contentsOf: tongueLocations.map({ $0 * rotationMatrix }))
        
        super.init(device: device,
                   size: size,
                   objects: SceneManager.marchGenerate(locations: locations,
                                                       materialType: .randomNormal),
//                   objects: SceneManager.generate(objectCount: 30,
//                                                  objectTypes: [.Box, .Sphere],
//                                                  generationType: .procedural,
//                                                  positionType: .radial,
//                                                  collisionType: [.grounded],
//                                                  objectSizeRange: (SIMD3<Float>(repeating: 0.1), SIMD3<Float>(repeating: 2)),
//                                                  objectPositionRange: (SIMD3<Float>(0, 0, 0), SIMD3<Float>(100, Float.pi * 2, 0)),
//                                                  materialType: .randomNormal),
                   inputManager: RayMarchingInputManager(renderSpecificInputs: [], imageSize: size),
                   imageCount: 2)
        name = "Vanilla Ray Trace Renderer"
        let functions = createFunctions(names: "rayMarch")
        if let rayFunction = functions[0] {
            do {
                rayPipeline = try device.makeComputePipelineState(function: rayFunction)
                skyTexture = try loadTexture(name: "christmas_photo_studio_04_4k")
                skySize = SIMD2<Int32>(Int32(skyTexture.width), Int32(skyTexture.height))
            } catch {
                print(error)
                fatalError()
            }
        }
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        
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
        rayEncoder?.setBytes([skyIntensity], length: MemoryLayout<Float>.stride, index: 8)
        rayEncoder?.setBytes([Int32(intermediateFrame)], length: MemoryLayout<Int32>.stride, index: 9)
        rayEncoder?.setBytes([Int32(iterations)], length: MemoryLayout<Int32>.stride, index: 10)
        rayEncoder?.setBytes([maxDistance], length: MemoryLayout<Float>.stride, index: 11)
        rayEncoder?.setBytes([precision], length: MemoryLayout<Float>.stride, index: 12)
        rayEncoder?.setTexture(skyTexture, index: 0)
        rayEncoder?.setTexture(images[0], index: 1)
        
        rayEncoder?.dispatchThreadgroups(getCappedGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        rayEncoder?.endEncoding()
        
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
}

class RayMarchingInputManager: RayInputManager {
    
    var iterations: Int {
        Int((getInput(13) as! SliderInput).output)
    }
    var maxDistance: Float {
        Float((getInput(14) as! SliderInput).output)
    }
    var precision: Float {
        Float((getInput(15) as! SliderInput).output)
    }
    
    override init(renderSpecificInputs: [NSView], imageSize: CGSize?) {
        let iterations = SliderInput(name: "Iterations", minValue: 1, currentValue: 100, maxValue: 1000)
        let maxDistance = SliderInput(name: "Max Distance", minValue: 0, currentValue: 400, maxValue: 1000)
        let precision = SliderInput(name: "Precision", minValue: 0.0001, currentValue: 0.1, maxValue: 1)
        super.init(renderSpecificInputs: [iterations, maxDistance, precision] + renderSpecificInputs, imageSize: imageSize)
    }
    
}
