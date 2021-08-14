//
//  FluidRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/25/21.
//

import MetalKit

class FluidRenderer: Renderer {
    
    var initializePipeline,
        advectPipeline,
        jacobiPipeline,
        forcePipeline,
        projectionSetupPipeline,
        projectionFinishPipeline,
        dyePipeline: MTLComputePipelineState!
    
    var dt: Float = 0.1
    var diffusionRate: Float = 1
    var viscosity: Float = 1
    
    var pressureIn: MTLTexture!
    var pressureOut: MTLTexture!
    var velocityIn: MTLTexture!
    var velocityOut: MTLTexture!
    var template: MTLTexture!
    var previousDye: MTLTexture!
    var dye: MTLTexture { outputImage }
    // image is ink texture
//    var previousVelocitty: MTLTexture!
    var additions = [SIMD2<Float>]()
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: BasicInputManager(imageSize: size), name: "Fluid Renderer")
        let functions = createFunctions("advect", "jacobi", "force", "projectionSetup", "projectionFinish", "initialize", "moveDye")
        advectPipeline = try! device.makeComputePipelineState(function: functions[0]!)
        jacobiPipeline = try! device.makeComputePipelineState(function: functions[1]!)
        forcePipeline = try! device.makeComputePipelineState(function: functions[2]!)
        projectionSetupPipeline = try! device.makeComputePipelineState(function: functions[3]!)
        projectionFinishPipeline = try! device.makeComputePipelineState(function: functions[4]!)
        initializePipeline = try! device.makeComputePipelineState(function: functions[5]!)
        dyePipeline = try! device.makeComputePipelineState(function: functions[6]!)
    }
    
    override func drawableSizeDidChange(size: CGSize) {
        super.drawableSizeDidChange(size: size)
        pressureIn = createTexture(size: size, editable: true)
        pressureOut = createTexture(size: size)
        velocityIn = createTexture(size: size, editable: true)
        velocityOut = createTexture(size: size)
        template = createTexture(size: size)
        previousDye = createTexture(size: size)
        initialized = false
    }
    
    override func setupResources(commandQueue: MTLCommandQueue?, semaphore: DispatchSemaphore) {
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else { print("failed command buffer"); return }
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: initializePipeline,
                               buffers: [],
                               bytes: { _, _ in },
                               textures: [velocityIn, pressureIn, outputImage],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        let copyEncoder = commandBuffer.makeBlitCommandEncoder()
        copyEncoder?.copy(from: dye, to: previousDye)
        copyEncoder?.endEncoding()
        
        commandBuffer.commit()
        super.setupResources(commandQueue: commandQueue, semaphore: semaphore)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: advectPipeline,
                               buffers: [],
                               bytes: { [self] encoder, offset in
                                encoder?.setBytes([dt], length: MemoryLayout<Float>.stride, index: 0 + offset)
                               },
                               textures: [velocityIn, velocityOut],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        var blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: velocityOut, to: velocityIn)
        blitEncoder?.copy(from: velocityOut, to: template)
        blitEncoder?.endEncoding()
        
        let dx = 1 / Float(size.width)
        let viscosity = 1e-6
        let alpha = dx * dx / (Float(viscosity) * dt);
        let beta = 4 + alpha
        for _ in 0..<20 {
            //jacobi
            dispatchComputeEncoder(commandBuffer: commandBuffer,
                                   computePipeline: jacobiPipeline,
                                   buffers: [],
                                   bytes: { encoder, offset in
                                    encoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: offset + 0)
                                    encoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: offset + 1)
                                   },
                                   textures: [velocityIn, velocityOut, template],
                                   threadGroups: getImageGroupSize(),
                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
            //swap jacobi
            dispatchComputeEncoder(commandBuffer: commandBuffer,
                                   computePipeline: jacobiPipeline,
                                   buffers: [],
                                   bytes: { encoder, offset in
                                    encoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: offset + 0)
                                    encoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: offset + 1)
                                   },
                                   textures: [velocityOut, velocityIn, template],
                                   threadGroups: getImageGroupSize(),
                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        }
        // No need for a blit encoder because jacobi pipeline will do the same
        // set force
        if additions.count > 0 {
            dispatchComputeEncoder(commandBuffer: commandBuffer,
                                   computePipeline: forcePipeline,
                                   buffers: [],
                                   bytes: { [self] encoder, offset in
                                    encoder?.setBytes(additions, length: MemoryLayout<SIMD2<Float>>.stride * additions.count, index: offset)
                                    encoder?.setBytes([Int32(additions.count)], length: MemoryLayout<Int32>.stride, index: offset + 1)
                                   },
                                   textures: [velocityOut, velocityIn, pressureIn],
                                   threadGroups: getImageGroupSize(),
                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
            additions = []
        }
        
        // project setup
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: projectionSetupPipeline,
                               buffers: [],
                               bytes: { _,_ in },
                               textures: [velocityIn, pressureIn, velocityOut],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        
        blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: pressureIn, to: template)
        blitEncoder?.endEncoding()
        
        for _ in 0..<20 {
            //jacobi
            dispatchComputeEncoder(commandBuffer: commandBuffer,
                                   computePipeline: jacobiPipeline,
                                   buffers: [],
                                   bytes: { encoder, offset in
                                    encoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: offset + 0)
                                    encoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: offset + 1)
                                   },
                                   textures: [pressureIn, pressureOut, template],
                                   threadGroups: getImageGroupSize(),
                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
            //swap jacobi
            dispatchComputeEncoder(commandBuffer: commandBuffer,
                                   computePipeline: jacobiPipeline,
                                   buffers: [],
                                   bytes: { encoder, offset in
                                    encoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: offset + 0)
                                    encoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: offset + 1)
                                   },
                                   textures: [pressureOut, pressureIn, template],
                                   threadGroups: getImageGroupSize(),
                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        }
        // project finish
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: projectionFinishPipeline,
                               buffers: [],
                               bytes: { _, _ in },
                               textures: [velocityIn, pressureIn, velocityOut],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        // dye?
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: dyePipeline,
                               buffers: [],
                               bytes: { _, _ in },
                               textures: [velocityOut, previousDye, dye],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        // synchronize?
        blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: dye, to: previousDye)
        blitEncoder?.endEncoding()
        
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
//    func addDensity(location: SIMD2<Int>) {
//        density.replace(
//            region: MTLRegion(origin: MTLOrigin(x: location.x, y: location.y, z: 0), size: MTLSize(width: 1, height: 1, depth: 1)),
//            mipmapLevel: 0,
//            withBytes: [SIMD4<Float>(0, 1, 0, 0)],
//            bytesPerRow: MemoryLayout<SIMD4<Float>>.stride * density.width)
//        
//    }
//    
//    
//    func addVelocity(location: SIMD2<Int>) {
//        memcpy(velocity.contents() + MemoryLayout<SIMD2<Float>>.stride * (location.x + location.y * Int(size.width)), [SIMD2<Float>(1, 1)], MemoryLayout<SIMD2<Float>>.stride)
//        velocity.didModifyRange(0..<velocity.length)
//    }
    
    func addVelocity(event: NSEvent, view: NSView) {
        guard let location = view.window?.contentView?.convert(event.locationInWindow, to: view) else { return }
        let coordinates = SIMD2<Float>(Float((location.x / view.bounds.size.width) * CGFloat(image.width)), Float((location.y / view.bounds.size.height) * CGFloat(image.height)))
        if coordinates.x >= 0 && coordinates.x < Float(image.width) && coordinates.y >= 0 && coordinates.y < Float(image.height) {
//            addDensity(location: coordinates)
            if MemoryLayout<SIMD2<Float>>.stride * (additions.count + 1) <= 4096 {
                additions.append(coordinates)
                print(additions.count)
            }
        }
    }
    
    override func mouseDown(event: NSEvent, view: NSView) {
        super.mouseDown(event: event, view: view)
        addVelocity(event: event, view: view)
    }
    
    override func mouseDragged(event: NSEvent, view: NSView) {
        super.mouseDragged(event: event, view: view)
        addVelocity(event: event, view: view)
    }
}
