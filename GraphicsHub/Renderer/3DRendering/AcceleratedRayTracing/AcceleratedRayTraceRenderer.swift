//
//  AcceleratedRayTraceRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/25/21.
//

import MetalKit
import MetalPerformanceShaders

class AcceleratedRayTraceRenderer: RayTraceRenderer {
    
    var rayPipeline: MTLComputePipelineState!
    
    var instanceBuffer: MTLBuffer!
//
//    let TRIANGLE_MASK_GEOMETRY: Int32 = 1
//    let TRIANGLE_MASK_LIGHT: Int32 = 2
//
//    let RAY_MASK_PRIMARY: Int32 = 3
//    let RAY_MASK_SHADOW: Int32 = 1
//    let RAY_MASK_SECONDARY: Int32 = 1
    
    var intersectionFunctions: MTLLinkedFunctions!
    var functionTable: MTLIntersectionFunctionTable!
    
    var accelerationStructure: MTLAccelerationStructure?
    
    var skyTexture: MTLTexture!
    var skySize: SIMD2<Int32>!
    
    required init(device: MTLDevice, size: CGSize) {
        let inputManager = RayTraceInputManager(size: size)
        super.init(device: device,
                   size: size,
                   objects: [Object.sphere(material: Material(albedo: SIMD3<Float>(1, 1, 0), specular: SIMD3<Float>(1, 0, 0), n: 1, transparency: 1),
                                           position: SIMD3<Float>(-1, 0, 0),
                                           size: SIMD3<Float>(1, 1, 1)),
                             Object.sphere(material: Material(albedo: SIMD3<Float>(0, 1, 0), specular: SIMD3<Float>(1, 0, 0), n: 1, transparency: 1),
                                                     position: SIMD3<Float>(0, 0, 0),
                                                     size: SIMD3<Float>(1, 1, 1)),
                             Object.sphere(material: Material(albedo: SIMD3<Float>(0, 0, 1), specular: SIMD3<Float>(1, 0, 0), n: 1, transparency: 1),
                                                     position: SIMD3<Float>(1, 0, 0),
                                                     size: SIMD3<Float>(1, 1, 1))],
                   inputManager: inputManager,
                   imageCount: 2)
        setupPipelines()
        computeSizeDidChange(size: inputManager.computeSize())
        do {
            skyTexture = try loadTexture(name: "cape_hill_4k")
            skySize = SIMD2<Int32>(Int32(skyTexture.width), Int32(skyTexture.height))
        } catch {
            print(error)
            fatalError()
        }
    }
    
    
    fileprivate func setupPipelines() {
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        
        let functions = createFunctions(names: "acceleratedRays", "boundingBoxIntersection")
        do {
            computeDescriptor.computeFunction = functions[0]
            rayPipeline = try device.makeComputePipelineState(descriptor: computeDescriptor,
                                                              options: [],
                                                              reflection: nil)
            let tableDescriptor = MTLIntersectionFunctionTableDescriptor()
            tableDescriptor.functionCount = 1
            functionTable = rayPipeline.makeIntersectionFunctionTable(descriptor: tableDescriptor)
            functionTable.setBuffer(objectBuffer, offset: 0, index: 0)
            // FIXME: Bind resource buffer
            let handle = rayPipeline.functionHandle(function: functions[1]!)
            functionTable.setFunction(handle, index: 0)
            
            
        } catch {
            print(error)
            fatalError()
        }
    }
    
    private func accelerationStructureWithDescriptor(descriptor: MTLAccelerationStructureDescriptor, commandQueue: MTLCommandQueue?) -> MTLAccelerationStructure {
        
        let accelSizes = device.accelerationStructureSizes(descriptor: descriptor)
        
        let accelerationStructure = device.makeAccelerationStructure(size: accelSizes.accelerationStructureSize)!
        let scratchBuffer = device.makeBuffer(length: accelSizes.buildScratchBufferSize, options: .storageModePrivate)!
        let compactedSizeBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.stride, options: .storageModeShared)!
        
        var commandBuffer = commandQueue?.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeAccelerationStructureCommandEncoder()
        
        commandEncoder?.build(accelerationStructure: accelerationStructure,
                              descriptor: descriptor,
                              scratchBuffer: scratchBuffer,
                              scratchBufferOffset: 0)
        commandEncoder?.writeCompactedSize(accelerationStructure: accelerationStructure,
                                           buffer: compactedSizeBuffer,
                                           offset: 0)
        commandEncoder?.endEncoding()
        commandBuffer?.commit()
        
        commandBuffer?.waitUntilCompleted()
        
        let compactedSize = compactedSizeBuffer.contents().assumingMemoryBound(to: UInt32.self).pointee
        let compactedAccelerationStructure = device.makeAccelerationStructure(size: Int(compactedSize))!
        
        commandBuffer = commandQueue?.makeCommandBuffer()
        let compactEncoder = commandBuffer?.makeAccelerationStructureCommandEncoder()
        compactEncoder?.copyAndCompact(sourceAccelerationStructure: accelerationStructure,
                                       destinationAccelerationStructure: compactedAccelerationStructure)
        compactEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        return compactedAccelerationStructure
    }
    
    override func setupResources(commandQueue: MTLCommandQueue?, semaphore: DispatchSemaphore) {
        
        var primitiveAccelerationStrucutures = [MTLAccelerationStructure]()
        instanceBuffer = device.makeBuffer(length: MemoryLayout<MTLAccelerationStructureInstanceDescriptor>.stride * objects.count,
                                                options: .storageModeManaged)
        let instances = instanceBuffer.contents().bindMemory(to: MTLAccelerationStructureInstanceDescriptor.self, capacity: objects.count)
        for (index, object) in objects.enumerated() {
            let geometryDescriptor: MTLAccelerationStructureGeometryDescriptor = {
                switch object.getType() {
                case .Sphere, .Box:
                    let descriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()
                    let boundingBoxes = object.boundingBoxes
                    descriptor.boundingBoxBuffer = device.makeBuffer(bytes: [boundingBoxes], length: MemoryLayout<Object.BoundingBox>.stride, options: .storageModeManaged)
                    descriptor.boundingBoxCount = 1
                    return descriptor
                default:
                    fatalError()
                }
            }()
//            geometryDescriptor.intersectionFunctionTableOffset = object.getIntersectionFunctionIndex()
            
            let primitiveDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
            primitiveDescriptor.geometryDescriptors = [ geometryDescriptor ]
            
            primitiveAccelerationStrucutures.append(accelerationStructureWithDescriptor(descriptor: primitiveDescriptor, commandQueue: commandQueue))
            
            instances[index].accelerationStructureIndex = UInt32(index)
            instances[index].options = .opaque
            // FIXME: Intersection table
            instances[index].intersectionFunctionTableOffset = 0
            // TODO: Masks
            instances[index].mask = ((1 << 6) - 1)
            
        }
        instanceBuffer.didModifyRange(0..<instanceBuffer.length)
        
        let accelerationDescriptor = MTLInstanceAccelerationStructureDescriptor()
        accelerationDescriptor.instancedAccelerationStructures = primitiveAccelerationStrucutures
        accelerationDescriptor.instanceCount = objects.count
        accelerationDescriptor.instanceDescriptorBuffer = instanceBuffer
        
        accelerationStructure = accelerationStructureWithDescriptor(descriptor: accelerationDescriptor, commandQueue: commandQueue)
        
        super.setupResources(commandQueue: commandQueue, semaphore: semaphore)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
//        guard let accelerator = accelerationStructure else { return }
        
        let threadGroups = getCappedGroupSize()
        let threadsPerThreadGroup = MTLSize(width: 8, height: 8, depth: 1)
        
        let rayEncoder = commandBuffer.makeComputeCommandEncoder()
        rayEncoder?.setComputePipelineState(rayPipeline)
        rayEncoder?.setBytes([size.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
        rayEncoder?.setBytes([computeSize.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
        rayEncoder?.setBytes([skySize], length: MemoryLayout<SIMD2<Int32>>.stride, index: 2)
        rayEncoder?.setBytes([SIMD2<Float>(Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5))], length: MemoryLayout<SIMD2<Float>>.stride, index: 3)
        rayEncoder?.setBytes([camera.makeModelMatrix()], length: MemoryLayout<float4x4>.stride, index: 4)
        rayEncoder?.setBytes([camera.makeProjectionMatrix()], length: MemoryLayout<float4x4>.stride, index: 5)
        rayEncoder?.setBytes([intermediateFrame], length: MemoryLayout<Int32>.stride, index: 6)
        rayEncoder?.setBuffer(objectBuffer, offset: 0, index: 7)
        rayEncoder?.setAccelerationStructure(accelerationStructure, bufferIndex: 8)
        rayEncoder?.setIntersectionFunctionTable(functionTable, bufferIndex: 9)
        rayEncoder?.setTexture(skyTexture, index: 0)
        rayEncoder?.setTexture(images[0], index: 1)
        
        rayEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerThreadGroup)
        rayEncoder?.endEncoding()

        super.draw(commandBuffer: commandBuffer, view: view)
    }
}

extension CGSize {
    func toVector() -> SIMD2<Int32> {
        return SIMD2(Int32(width), Int32(height))
    }
}
