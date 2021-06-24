//
//  WWDCCornellBox.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/24/21.
//

import MetalKit
import MetalPerformanceShaders

class CornellBox: AntialiasingRenderer {
    
    var rayPipeline, shadePipeline, shadowPipeline: MTLComputePipelineState!
    
    let maxFramesInFlight = 3
    let alignedUniformsSize = (MemoryLayout<Uniforms>.stride + 255) & ~255
    let rayStride = 48
    let intersectionStride = MemoryLayout<MPSIntersectionDistancePrimitiveIndexCoordinates>.stride
    
    var accelerationStructure: MPSTriangleAccelerationStructure!
    var intersector: MPSRayIntersector!
    
    var vertexPositionBuffer,
        vertexNormalBuffer,
        vertexColorBuffer,
        rayBuffer,
        shadowRayBuffer,
        intersectionBuffer,
        uniformBuffer,
        randomBuffer,
        triangleMaskBuffer: MTLBuffer!
    
    var randomBufferOffset, uniformBufferOffset: Int!
    var uniformBufferIndex = 0
    
    let TRIANGLE_MASK_GEOMETRY: Int32 = 1
    let TRIANGLE_MASK_LIGHT: Int32 = 2

    let RAY_MASK_PRIMARY: Int32 = 3
    let RAY_MASK_SHADOW: Int32 = 1
    let RAY_MASK_SECONDARY: Int32 = 1
    
    
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device,
                   size: size,
                   inputManager: AntialiasingInputManager(renderSpecificInputs: [], imageSize: size),
                   imageCount: 2)
        setupPipelines()
        setupScene()
        setupBuffers()
        setupIntersector()
        updateUniforms()
    }
    
    fileprivate func setupPipelines() {
        let computeDescriptor = MTLComputePipelineDescriptor()
        computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
        
        let functions = createFunctions(names: "rayKernel", "shadeKernel", "shadowKernel")
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
        let uniformBufferSize = alignedUniformsSize * maxFramesInFlight
        uniformBuffer = device.makeBuffer(length: uniformBufferSize, options: .storageModeManaged)
        randomBuffer = device.makeBuffer(length: 256 * MemoryLayout<SIMD2<Float>>.stride * maxFramesInFlight, options: .storageModeManaged)
        
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
    
    fileprivate func updateUniforms() {
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        let pointer = uniformBuffer!.contents().advanced(by: uniformBufferOffset)
        let uniforms = pointer.bindMemory(to: Uniforms.self, capacity: 1)
        uniforms.pointee.camera.position = SIMD3(0.0, 1.0, 3.38)
        uniforms.pointee.camera.forward = SIMD3(0.0, 0.0, -1.0)
        uniforms.pointee.camera.right = SIMD3(1.0, 0.0, 0.0)
        uniforms.pointee.camera.up = SIMD3(0.0, 1.0, 0.0)
        uniforms.pointee.light.position = SIMD3(0.0, 1.98, 0.0)
        uniforms.pointee.light.forward = SIMD3(0.0, -1.0, 0.0)
        uniforms.pointee.light.right = SIMD3(0.25, 0.0, 0.0)
        uniforms.pointee.light.up = SIMD3(0.0, 0.0, 0.25)
        uniforms.pointee.light.color = SIMD3(repeating: 12.0)
      
        let fieldOfView = 45.0 * (Float.pi / 180.0)
        let aspectRatio = Float(size.width) / Float(size.height)
        let imagePlaneHeight = tanf(fieldOfView / 2.0)
        let imagePlaneWidth = aspectRatio * imagePlaneHeight
      
        uniforms.pointee.camera.right *= imagePlaneWidth
        uniforms.pointee.camera.up *= imagePlaneHeight
        uniforms.pointee.width = uint(size.width)
        uniforms.pointee.height = uint(size.height)
        uniforms.pointee.blocksWide = (uniforms.pointee.width + 15) / 16
        uniforms.pointee.frameIndex = UInt32(renderPasses)
        uniformBuffer?.didModifyRange(uniformBufferOffset..<(uniformBufferOffset + alignedUniformsSize))
        randomBufferOffset = 256 * MemoryLayout<SIMD2<Float>>.stride * uniformBufferIndex
        let p = randomBuffer!.contents().advanced(by: randomBufferOffset)
        var random = p.bindMemory(to: SIMD2<Float>.self, capacity: 1)
        for _ in 0..<256 {
            random.pointee = SIMD2<Float>(Float(drand48()), Float(drand48()) )
            random = random.advanced(by: 1)
            
        }
        randomBuffer?.didModifyRange(randomBufferOffset..<(randomBufferOffset + 256 * MemoryLayout<SIMD2<Float>>.stride))
        uniformBufferIndex = (uniformBufferIndex + 1) % maxFramesInFlight
    }
    
    struct Camera {
        var position: SIMD3<Float>
        var right: SIMD3<Float>
        var up: SIMD3<Float>
        var forward: SIMD3<Float>
    }

    struct AreaLight {
        var position: SIMD3<Float>
        var forward: SIMD3<Float>
        var right: SIMD3<Float>
        var up: SIMD3<Float>
        var color: SIMD3<Float>
    }

    struct Uniforms {
        var width: UInt32
        var height: UInt32
        var blocksWide: UInt32
        var frameIndex: UInt32
        var camera: Camera
        var light: AreaLight
    }
    
    override func drawableSizeDidChange(size: CGSize) {
        super.drawableSizeDidChange(size: size)
        
        let rayCount = Int(size.width * size.height)
        rayBuffer = device.makeBuffer(length: rayStride * rayCount,  options: .storageModePrivate)
        shadowRayBuffer = device.makeBuffer(length: rayStride * rayCount, options: .storageModePrivate)
        intersectionBuffer = device.makeBuffer(length: intersectionStride * rayCount, options: .storageModePrivate)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        updateUniforms()
        
        let width = Int(size.width)
        let height = Int(size.height)
        let threadsPerThreadgroup = MTLSizeMake(8, 8, 1)
        let threadgroups = MTLSizeMake(
          (width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
          (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
          1)
        
        // 1st compute pipeline - Primary Rays
        var computeEncoder = commandBuffer.makeComputeCommandEncoder()
        computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
        computeEncoder?.setBuffer(rayBuffer, offset: 0, index: 1)
        computeEncoder?.setBuffer(randomBuffer, offset: randomBufferOffset, index: 2)
        computeEncoder?.setTexture(images[0], index: 0)
        computeEncoder?.setComputePipelineState(rayPipeline!)
        computeEncoder?.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder?.endEncoding()
        // 2nd and 3rd compute pipelines
        for _ in 0..<3 {
          // Shade pipeline
          intersector?.intersectionDataType = .distancePrimitiveIndexCoordinates
          intersector?.encodeIntersection(commandBuffer: commandBuffer,
                                          intersectionType: .nearest,
                                          rayBuffer: rayBuffer!,
                                          rayBufferOffset: 0,
                                          intersectionBuffer: intersectionBuffer!,
                                          intersectionBufferOffset: 0,
                                          rayCount: width * height,
                                          accelerationStructure: accelerationStructure!)
          computeEncoder = commandBuffer.makeComputeCommandEncoder()
          computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
          computeEncoder?.setBuffer(rayBuffer, offset: 0, index: 1)
          computeEncoder?.setBuffer(shadowRayBuffer, offset: 0, index: 2)
          computeEncoder?.setBuffer(intersectionBuffer, offset: 0, index: 3)
          computeEncoder?.setBuffer(vertexColorBuffer, offset: 0, index: 4)
          computeEncoder?.setBuffer(vertexNormalBuffer, offset: 0, index: 5)
          computeEncoder?.setBuffer(randomBuffer, offset: randomBufferOffset, index: 6)
          computeEncoder?.setBuffer(triangleMaskBuffer, offset: 0, index: 7)
          computeEncoder?.setTexture(images[0], index: 0)
          computeEncoder?.setComputePipelineState(shadePipeline!)
          computeEncoder?.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
          computeEncoder?.endEncoding()
          // Shadows pipeline
          intersector?.intersectionDataType = .distance
          intersector?.encodeIntersection(commandBuffer: commandBuffer,
                                          intersectionType: .any,
                                          rayBuffer: shadowRayBuffer!,
                                          rayBufferOffset: 0,
                                          intersectionBuffer: intersectionBuffer!,
                                          intersectionBufferOffset: 0,
                                          rayCount: width * height,
                                          accelerationStructure: accelerationStructure!)
          computeEncoder = commandBuffer.makeComputeCommandEncoder()
          computeEncoder?.setBuffer(uniformBuffer, offset: uniformBufferOffset, index: 0)
          computeEncoder?.setBuffer(shadowRayBuffer, offset: 0, index: 1)
          computeEncoder?.setBuffer(intersectionBuffer, offset: 0, index: 2)
          computeEncoder?.setTexture(images[0], index: 0)
          computeEncoder?.setComputePipelineState(shadowPipeline!)
          computeEncoder?.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
          computeEncoder?.endEncoding()
        }
        
        super.draw(commandBuffer: commandBuffer, view: view)
    }
}
