//
//  AcceleratedRayTraceRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/25/21.
//

import MetalKit
import MetalPerformanceShaders

class AcceleratedRayTraceRenderer: RayTraceRenderer {
    
    var rayPipeline, shadePipeline, shadowPipeline, copyPipeline: MTLComputePipelineState!
    
    var instanceBuffer,
        rayBuffer,
        shadowRayBuffer,
        intersectionBuffer,
        triangleMaskBuffer: MTLBuffer!
    
    let TRIANGLE_MASK_GEOMETRY: Int32 = 1
    let TRIANGLE_MASK_LIGHT: Int32 = 2

    let RAY_MASK_PRIMARY: Int32 = 3
    let RAY_MASK_SHADOW: Int32 = 1
    let RAY_MASK_SECONDARY: Int32 = 1
    
    let rayStride = MemoryLayout<Ray>.stride // 48
    
    var intersectionFunctions: MTLLinkedFunctions!
    var functionTable: MTLIntersectionFunctionTable!
    
    private var initialized = false
    private var primitiveDescriptor: MTLAccelerationStructureDescriptor?
    
    private var accelerationDescriptor: MTLInstanceAccelerationStructureDescriptor?
    var accelerationStructure: MTLAccelerationStructure?
    
    required init(device: MTLDevice, size: CGSize) {
        let inputManager = RayTraceInputManager(size: size)
        super.init(device: device,
                   size: size,
                   objects: SceneManager.generate(objectCount: 10,
                                                  objectTypes: [.Sphere, .Box],
                                                  generationType: .procedural,
                                                  positionType: .radial,
                                                  collisionType: [.distinct, .grounded],
                                                  objectSizeRange: (SIMD3<Float>(repeating: 0.1), SIMD3<Float>(repeating: 2)),
                                                  objectPositionRange: (SIMD3<Float>(0, 0, 0), SIMD3<Float>(100, Float.pi * 2, 0)),
                                                  materialType: .random),
                   inputManager: inputManager,
                   imageCount: 2)
        setupPipelines()
        setupIntersector()
        computeSizeDidChange(size: inputManager.computeSize())
    }
    
    
    fileprivate func setupPipelines() {
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        
        let functions = createFunctions(names: "populateRays", "shadeRays", "shadowRays", "copyRaysToTexture")
        do {
            computeDescriptor.computeFunction = functions[0]
            rayPipeline = try device.makeComputePipelineState(descriptor: computeDescriptor,
                                                              options: [],
                                                              reflection: nil)
            computeDescriptor.computeFunction = functions[1]
            shadePipeline = try device.makeComputePipelineState(descriptor: computeDescriptor,
                                                                options: [],
                                                                reflection: nil)
            computeDescriptor.computeFunction = functions[2]
            shadowPipeline = try device.makeComputePipelineState(descriptor: computeDescriptor,
                                                                 options: [],
                                                                 reflection: nil)
            computeDescriptor.computeFunction = functions[3]
            copyPipeline = try device.makeComputePipelineState(descriptor: computeDescriptor,
                                                                 options: [],
                                                                 reflection: nil)
        } catch {
            print(error)
            fatalError()
        }
    }
    
    fileprivate func setupIntersectionFunctions() {
        
        
    }
    
    fileprivate func setupIntersector() {
        struct BoundingBox {
            var min: MTLPackedFloat3
            var max: MTLPackedFloat3
        }
        
        var boundingBoxes = [BoundingBox]()
        
        let convert: (SIMD3<Float>) -> MTLPackedFloat3 = { vector in
            var output = MTLPackedFloat3()
            output.x = vector.x
            output.y = vector.y
            output.z = vector.z
            return output
        }
        
        for object in objects {
            switch object.getType() {
            case .Box:
                boundingBoxes.append(BoundingBox(min: convert(object.position - object.size / 2),
                                                 max: convert(object.position + object.size / 2)))
            case .Sphere:
                boundingBoxes.append(BoundingBox(min: convert(object.position - SIMD3(repeating: object.radius) / 2),
                                                 max: convert(object.position + SIMD3(repeating: object.radius) / 2)))
            default:
                continue
            }
        }
        if boundingBoxes.count > 0 {
            let geometryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()
            geometryDescriptor.boundingBoxBuffer = device.makeBuffer(bytes: boundingBoxes, length: MemoryLayout<SIMD3<Float>>.stride * boundingBoxes.count, options: .storageModeManaged)
            geometryDescriptor.boundingBoxCount = boundingBoxes.count / 2
            
            let primitiveDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
            primitiveDescriptor.usage = .preferFastBuild
            primitiveDescriptor.geometryDescriptors = [geometryDescriptor]
            
            self.primitiveDescriptor = primitiveDescriptor
            
            instanceBuffer = device.makeBuffer(length: MemoryLayout<MTLAccelerationStructureInstanceDescriptor>.stride * objects.count, options: .storageModeManaged)
            let instancePointer = instanceBuffer.contents().assumingMemoryBound(to: MTLAccelerationStructureInstanceDescriptor.self)
            for (index,object) in objects.enumerated() {
                instancePointer[index].accelerationStructureIndex = 0
                instancePointer[index].options = MTLAccelerationStructureInstanceOptions(rawValue: 0)
                instancePointer[index].intersectionFunctionTableOffset = UInt32(object.getType()?.rawValue ?? 0)
                // TODO: MASK?
            }
            instanceBuffer.didModifyRange(0..<instanceBuffer.length)
            
            let accelerationDescriptor = MTLInstanceAccelerationStructureDescriptor()
            accelerationDescriptor.instanceCount = objects.count
            accelerationDescriptor.instanceDescriptorBuffer = instanceBuffer
            
        }
//
//        accelerationStructure = MPSTriangleAccelerationStructure(device: device)
//        accelerationStructure?.vertexBuffer = vertexPositionBuffer
//        accelerationStructure?.maskBuffer = triangleMaskBuffer
//        accelerationStructure?.triangleCount = vertices.count / 3
//        accelerationStructure?.rebuild()
    }
    
    override func computeSizeDidChange(size: CGSize) {
        super.computeSizeDidChange(size: size)
        self.rayBuffer = device.makeBuffer(length: rayStride * Int(size.width * size.height), options: .storageModeManaged)
        self.shadowRayBuffer = device.makeBuffer(length: rayStride * Int(size.width * size.height), options: .storageModeManaged)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
         
        if !initialized, let descriptor = primitiveDescriptor {
            let sizes = device.accelerationStructureSizes(descriptor: descriptor)
            
            let accelerationStructure = device.makeAccelerationStructure(size: sizes.accelerationStructureSize)!
            self.accelerationStructure = accelerationStructure
            let scrathBuffer = device.makeBuffer(length: sizes.buildScratchBufferSize, options: .storageModePrivate)!
            
            let acceleratorEncoder = commandBuffer.makeAccelerationStructureCommandEncoder()
            acceleratorEncoder?.build(accelerationStructure: accelerationStructure,
                                      descriptor: descriptor,
                                      scratchBuffer: scrathBuffer,
                                      scratchBufferOffset: 0)
            acceleratorEncoder?.endEncoding()
            initialized = true
            return
        }
        
        let threadGroups = getCappedGroupSize()
        let threadsPerThreadGroup = MTLSize(width: 8, height: 8, depth: 1)
        
        let rayEncoder = commandBuffer.makeComputeCommandEncoder()
        rayEncoder?.setComputePipelineState(rayPipeline)
        rayEncoder?.setBuffer(rayBuffer, offset: 0, index: 0)
        rayEncoder?.setBytes([size.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
        rayEncoder?.setBytes([computeSize.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 2)
        rayEncoder?.setBytes([SIMD2<Float>(Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5))], length: MemoryLayout<SIMD2<Float>>.stride, index: 3)
        rayEncoder?.setBytes([camera.makeModelMatrix()], length: MemoryLayout<float4x4>.stride, index: 4)
        rayEncoder?.setBytes([camera.makeProjectionMatrix()], length: MemoryLayout<float4x4>.stride, index: 5)
        rayEncoder?.setBytes([intermediateFrame], length: MemoryLayout<Int32>.stride, index: 6)
        rayEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadGroup)
        rayEncoder?.endEncoding()
        
//        for _ in 0..<1 {
//            intersector.intersectionDataType = .distancePrimitiveIndexCoordinates
//            intersector.encodeIntersection(commandBuffer: commandBuffer,
//                                           intersectionType: .nearest,
//                                           rayBuffer: rayBuffer,
//                                           rayBufferOffset: 0,
//                                           intersectionBuffer: intersectionBuffer,
//                                           intersectionBufferOffset: 0,
//                                           rayCount: Int(computeSize.width * computeSize.height),
//                                           accelerationStructure: accelerationStructure)
//            let shadeEncoder = commandBuffer.makeComputeCommandEncoder()
//
//            shadeEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadGroup)
//            shadeEncoder?.endEncoding()
//        }

        let copyEncoder = commandBuffer.makeComputeCommandEncoder()
        copyEncoder?.setComputePipelineState(copyPipeline)
        copyEncoder?.setBuffer(rayBuffer, offset: 0, index: 0)
        copyEncoder?.setBytes([size.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
        copyEncoder?.setBytes([computeSize.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 2)
        copyEncoder?.setBytes([intermediateFrame], length: MemoryLayout<Int32>.stride, index: 3)
        copyEncoder?.setTexture(images[0], index: 0)
        copyEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadGroup)
        copyEncoder?.endEncoding()
        
        super.draw(commandBuffer: commandBuffer, view: view)
    }
}

extension CGSize {
    func toVector() -> SIMD2<Int32> {
        return SIMD2(Int32(width), Int32(height))
    }
}
