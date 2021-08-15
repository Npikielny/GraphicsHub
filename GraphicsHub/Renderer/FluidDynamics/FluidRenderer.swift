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
    
    var p1: MTLTexture!
    var p2: MTLTexture!
    var v1: MTLTexture!
    var v2: MTLTexture!
    var v3: MTLTexture!
    var template: MTLTexture!
    var previousDye: MTLTexture!
    var dye: MTLTexture { outputImage }
    // image is ink texture
//    var previousVelocitty: MTLTexture!
    var additions = [SIMD2<Float>]()
    
    var lastLocation: SIMD2<Float> = SIMD2(0, 0)
    var currentLocation: SIMD2<Float> = SIMD2(0, 0)
    var mouseDown = false
    
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
        p1 = createTexture(size: size)
        p2 = createTexture(size: size)
        v1 = createTexture(size: size)
        v2 = createTexture(size: size)
        v3 = createTexture(size: size)
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
                               textures: [v1, v2, v3, p1, p2, dye],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        let copyEncoder = commandBuffer.makeBlitCommandEncoder()
        copyEncoder?.copy(from: dye, to: previousDye)
        copyEncoder?.endEncoding()
        
        commandBuffer.commit()
        super.setupResources(commandQueue: commandQueue, semaphore: semaphore)
    }
    
    var resolutionY: Int { getImageGroupSize().height * 8 }
    var resolutionX: Int { getImageGroupSize().width * 8 }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        // advect
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: advectPipeline,
                               buffers: [],
                               bytes: { [self] encoder, offset in
                                encoder?.setBytes([dt], length: MemoryLayout<Float>.stride, index: 0 + offset)
                               },
                               textures: [v1, v2],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))

        var blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: v2, to: v1)
        blitEncoder?.endEncoding()

        let dx = 1 / Float(resolutionY)

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
                                   textures: [v2, v3, v1],
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
                                   textures: [v3, v2, v1],
                                   threadGroups: getImageGroupSize(),
                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        }
        // No need for a blit encoder because jacobi pipeline will do the same
        // set force
        let multiplier: Float = mouseDown ? 300 : 0
//        let multiplier: Float = 300
        print(multiplier)
        let forceVector = (currentLocation - lastLocation) * multiplier
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: forcePipeline,
                               buffers: [],
                               bytes: { [self] encoder, offset in
                                encoder?.setBytes([forceVector], length: MemoryLayout<SIMD2<Float>>.stride, index: offset)
                                encoder?.setBytes([currentLocation], length: MemoryLayout<SIMD2<Float>>.stride, index: offset + 1)
                               },
                               textures: [v2, v3], // FIXME: Change v1 to v3
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        additions = []
        

        // project setup
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: projectionSetupPipeline,
                               buffers: [],
                               bytes: { _,_ in },
                               textures: [v3, v2, p1],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
////
////        blitEncoder = commandBuffer.makeBlitCommandEncoder()
////        blitEncoder?.copy(from: p1, to: template)
////        blitEncoder?.endEncoding()
////
        for _ in 0..<20 {
            //jacobi
            dispatchComputeEncoder(commandBuffer: commandBuffer,
                                   computePipeline: jacobiPipeline,
                                   buffers: [],
                                   bytes: { encoder, offset in
                                    encoder?.setBytes([-dx * dx], length: MemoryLayout<Float>.stride, index: offset + 0)
                                    encoder?.setBytes([Float(4)], length: MemoryLayout<Float>.stride, index: offset + 1)
                                   },
                                   textures: [p1, p2, v2],
                                   threadGroups: getImageGroupSize(),
                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
            //swap jacobi
            dispatchComputeEncoder(commandBuffer: commandBuffer,
                                   computePipeline: jacobiPipeline,
                                   buffers: [],
                                   bytes: { encoder, offset in
                                    encoder?.setBytes([-dx * dx], length: MemoryLayout<Float>.stride, index: offset + 0)
                                    encoder?.setBytes([Float(4)], length: MemoryLayout<Float>.stride, index: offset + 1)
                                   },
                                   textures: [p2, p1, v2],
                                   threadGroups: getImageGroupSize(),
                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        }
        // project finish
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: projectionFinishPipeline,
                               buffers: [],
                               bytes: { _, _ in },
                               textures: [v3, p1, v1],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        // dye?
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: dyePipeline,
                               buffers: [],
                               bytes: { _, _ in },
                               textures: [v1, previousDye, dye],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        // synchronize?
//        blitEncoder = commandBuffer.makeBlitCommandEncoder()
//        blitEncoder?.copy(from: dye, to: previousDye)
//        blitEncoder?.endEncoding()
        lastLocation = currentLocation
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
    func getLocation(event: NSEvent, view: NSView) -> SIMD2<Float>? {
        guard let location = view.window?.contentView?.convert(event.locationInWindow, to: view) else { return nil}
//        return SIMD2<Float>(Float((location.x / view.bounds.size.width) * CGFloat(image.width)), Float((location.y / view.bounds.size.height) * CGFloat(image.height))) / SIMD2(Float(view.bounds.size.width), Float(view.bounds.size.height))
        return SIMD2<Float>(Float((location.x / view.bounds.size.width)), Float((location.y / view.bounds.size.height))) - 0.5
    }
    
    override func mouseDown(event: NSEvent, view: NSView) {
        super.mouseDown(event: event, view: view)
//        guard let location = getLocation(event: event, view: view) else { return }
//        if !mouseDown {
//            lastLocation = location
//        }
//        currentLocation = location
//        mouseDown = true
        mouseDown.toggle()
    }
    
    override func mouseUp(event: NSEvent, view: NSView) {
        super.mouseUp(event: event, view: view)
//        mouseDown = false
    }
    
    override func mouseMoved(event: NSEvent, view: NSView) {
        super.mouseMoved(event: event, view: view)
        guard let location = getLocation(event: event, view: view) else { return }
        currentLocation = location
    }
}
