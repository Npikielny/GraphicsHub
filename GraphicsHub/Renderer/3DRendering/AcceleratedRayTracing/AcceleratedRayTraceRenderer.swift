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
    
    var accelerationStructure: MPSTriangleAccelerationStructure!
    var intersector: MPSRayIntersector!
    
    var vertexPositionBuffer,
        vertexNormalBuffer,
        vertexColorBuffer,
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
    
    required init(device: MTLDevice, size: CGSize) {
        let inputManager = RayTraceInputManager(size: size)
        super.init(device: device,
                   size: size,
                   objects: SceneManager.generate(objectCount: 0,
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
        setupScene()
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
    
    fileprivate func setupScene() {
        // light source
        var transform = translate(tx: 0, ty: 1, tz: 0.3) * scale(sx: 0.5, sy: 1.98, sz: 0.5)
        createCube(faceMask: .positiveY,
                   color: SIMD3(1, 1, 1),
                   transform: transform,
                   inwardNormals: true,
                   triangleMask: TRIANGLE_MASK_LIGHT)
        // top wall
        transform = translate(tx: 0, ty: 1, tz: 0) * scale(sx: 2, sy: 2, sz: 2)
        createCube(faceMask: .positiveY,
                   color: SIMD3(0.02, 0.4, 0.02),
                   transform: transform,
                   inwardNormals: true,
                   triangleMask: TRIANGLE_MASK_GEOMETRY)
        // bottom and back walls
        createCube(faceMask: [.negativeY, .negativeZ],
                   color: SIMD3(1, 1, 1),
                   transform: transform,
                   inwardNormals: true,
                   triangleMask: TRIANGLE_MASK_GEOMETRY)
        // left wall
        createCube(faceMask: .negativeX,
                   color: SIMD3(1, 0.02, 0.02),
                   transform: transform,
                   inwardNormals: true,
                   triangleMask: TRIANGLE_MASK_GEOMETRY)
        // right wall
        createCube(faceMask: [.positiveX],
                   color: SIMD3(0.02, 0.02, 0.2),
                   transform: transform,
                   inwardNormals: true,
                   triangleMask: TRIANGLE_MASK_GEOMETRY)
        // short box
        transform = translate(tx: 0.35,
                              ty: 0.3,
                              tz: 0.3725) *
            rotate(radians: -0.3,
                   axis: SIMD3(0.0, 1.0, 0.0)) * scale(sx: 0.6,
                                                       sy: 0.6,
                                                       sz: 0.6)
        createCube(faceMask: .all,
                   color: SIMD3(1.0, 1.0, 0.3),
                   transform: transform,
                   inwardNormals: false,
                   triangleMask: TRIANGLE_MASK_GEOMETRY)
        // tall box
        transform = translate(tx: -0.4, ty: 0.6, tz: -0.29) *
            rotate(radians: 0.3, axis: SIMD3(0.0, 1.0, 0.0)) *
            scale(sx: 0.6, sy: 1.2, sz: 0.6)
        createCube(faceMask: .all,
                   color: SIMD3(1.0, 1.0, 0.3),
                   transform: transform, inwardNormals: false, triangleMask: TRIANGLE_MASK_GEOMETRY)
    }
    
    fileprivate func setupBuffers() {
        vertexPositionBuffer = device.makeBuffer(bytes: &vertices, length: vertices.count * MemoryLayout<SIMD3<Float>>.stride, options: .storageModeManaged)
        vertexColorBuffer = device.makeBuffer(bytes: &colors, length: colors.count * MemoryLayout<SIMD3<Float>>.stride, options: .storageModeManaged)
        vertexNormalBuffer = device.makeBuffer(bytes: &normals, length: normals.count * MemoryLayout<SIMD3<Float>>.stride, options: .storageModeManaged)
        triangleMaskBuffer = device.makeBuffer(bytes: &masks, length: masks.count * MemoryLayout<uint>.stride, options: .storageModeManaged)
        
        for buffer in [ vertexPositionBuffer, vertexColorBuffer, vertexNormalBuffer, triangleMaskBuffer] {
            buffer?.didModifyRange(0..<buffer!.length)
        }
    }
    
    fileprivate func setupIntersector() {
        intersector = MPSRayIntersector(device: device)
        intersector?.rayDataType = .originMaskDirectionMaxDistance
        intersector?.rayStride = rayStride
        intersector?.rayMaskOptions = .primitive
        
        accelerationStructure = MPSTriangleAccelerationStructure(device: device)
        accelerationStructure?.vertexBuffer = vertexPositionBuffer
        accelerationStructure?.maskBuffer = triangleMaskBuffer
        accelerationStructure?.triangleCount = vertices.count / 3
        accelerationStructure?.rebuild()
    }
    
    override func computeSizeDidChange(size: CGSize) {
        super.computeSizeDidChange(size: size)
        self.rayBuffer = device.makeBuffer(length: rayStride * Int(size.width * size.height), options: .storageModeManaged)
        self.shadowRayBuffer = device.makeBuffer(length: rayStride * Int(size.width * size.height), options: .storageModeManaged)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
         
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
//
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
