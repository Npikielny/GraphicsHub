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
    
    var dt: Float = 1 / 60
    var diffusionRate: Float = 1
    
    var p1: MTLTexture!
    var p2: MTLTexture!
    var v1: MTLTexture!
    var v2: MTLTexture!
    var v3: MTLTexture!
    var template: MTLTexture!
    var previousDye: MTLTexture!
    var dye: MTLTexture { outputImage }
    // image is ink texture
    
    var lastLocation: SIMD2<Float> = SIMD2(0, 0)
    var currentLocation: SIMD2<Float> = SIMD2(0, 0)
    var mouseDown = false
    
    var dx: Float { 1 / Float(resolutionY) }
    var viscosity: Float { 1e-6 }
    var alpha: Float { dx * dx / (Float(viscosity) * dt); }
    var beta: Float { 4 + alpha }
    
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
        advect(commandBuffer: commandBuffer)
        
        jacobi2(commandBuffer: commandBuffer)
        // set force
        force(commandBuffer: commandBuffer)
        // project setup
        projectSetup(commandBuffer: commandBuffer)
        // jacobi 2
        jacobi1(commandBuffer: commandBuffer)
        // project finish
        projectFinish(commandBuffer: commandBuffer)
//        // dye?
        blit(commandBuffer: commandBuffer, drawingTexture: v1)
//        dye(commandBuffer: commandBuffer)
        
//        // synchronize?
//        blitEncoder = commandBuffer.makeBlitCommandEncoder()
//        blitEncoder?.copy(from: dye, to: previousDye)
//        blitEncoder?.endEncoding()
        lastLocation = currentLocation
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
    func advect(commandBuffer: MTLCommandBuffer) {
        let advectEncoder = commandBuffer.makeComputeCommandEncoder()
        advectEncoder?.setComputePipelineState(advectPipeline)
        advectEncoder?.setBytes([dt], length: MemoryLayout<Float>.stride, index: 0)
        advectEncoder?.setTextures([v1, v2], range: 0..<2)
        advectEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        advectEncoder?.endEncoding()
        
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: v2, to: v1)
        blitEncoder?.endEncoding()
    }
    
    func jacobi2(commandBuffer: MTLCommandBuffer) {
        for _ in 0..<20 {
            // jacobi
            var jacobiEncoder = commandBuffer.makeComputeCommandEncoder()
            jacobiEncoder?.setComputePipelineState(jacobiPipeline)
            jacobiEncoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: 0)
            jacobiEncoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: 1)
            jacobiEncoder?.setTextures([v2, v3, v1], range: 0..<3)
            jacobiEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            jacobiEncoder?.endEncoding()
            
            jacobiEncoder = commandBuffer.makeComputeCommandEncoder()
            jacobiEncoder?.setComputePipelineState(jacobiPipeline)
            jacobiEncoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: 0)
            jacobiEncoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: 1)
            jacobiEncoder?.setTextures([v3, v2, v1], range: 0..<3)
            jacobiEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            jacobiEncoder?.endEncoding()
            
//            //jacobi
//            dispatchComputeEncoder(commandBuffer: commandBuffer,
//                                   computePipeline: jacobiPipeline,
//                                   buffers: [],
//                                   bytes: { encoder, offset in
//                                    encoder?.setBytes([self.alpha], length: MemoryLayout<Float>.stride, index: offset + 0)
//                                    encoder?.setBytes([self.beta], length: MemoryLayout<Float>.stride, index: offset + 1)
//                                   },
//                                   textures: [v2, v3, v1],
//                                   threadGroups: getImageGroupSize(),
//                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
//            //swap jacobi
//            dispatchComputeEncoder(commandBuffer: commandBuffer,
//                                   computePipeline: jacobiPipeline,
//                                   buffers: [],
//                                   bytes: { encoder, offset in
//                                    encoder?.setBytes([self.alpha], length: MemoryLayout<Float>.stride, index: offset + 0)
//                                    encoder?.setBytes([self.beta], length: MemoryLayout<Float>.stride, index: offset + 1)
//                                   },
//                                   textures: [v3, v2, v1],
//                                   threadGroups: getImageGroupSize(),
//                                   threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
        }
        // No need for a blit encoder because jacobi pipeline will do the same
    }
    
    func force(commandBuffer: MTLCommandBuffer) {
        let forceVector = (currentLocation - lastLocation) * (mouseDown ? 1 : 0)
        let forceEncoder = commandBuffer.makeComputeCommandEncoder()
        forceEncoder?.setComputePipelineState(forcePipeline)
        forceEncoder?.setBytes([forceVector], length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
        forceEncoder?.setBytes([currentLocation], length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
        forceEncoder?.setBytes([300], length: MemoryLayout<Float>.stride, index: 2)
        forceEncoder?.setTextures([v2, v3], range: 0..<2)
        forceEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        forceEncoder?.endEncoding()
    }
    
    func projectSetup(commandBuffer: MTLCommandBuffer) {
        let projectionSetupEncoder = commandBuffer.makeComputeCommandEncoder()
        projectionSetupEncoder?.setComputePipelineState(projectionSetupPipeline)
        projectionSetupEncoder?.setTextures([v3, v2, p1], range: 0..<3)
        projectionSetupEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        projectionSetupEncoder?.endEncoding()
    }
    
    func jacobi1(commandBuffer: MTLCommandBuffer) {
        for _ in 0..<20 {
            var jacobiEncoder = commandBuffer.makeComputeCommandEncoder()
            jacobiEncoder?.setComputePipelineState(jacobiPipeline)
            jacobiEncoder?.setBytes([-dx * dx], length: MemoryLayout<Float>.stride, index: 0)
            jacobiEncoder?.setBytes([Float(4)], length: MemoryLayout<Float>.stride, index: 1)
            jacobiEncoder?.setTextures([p1, p2, v2], range: 0..<3)
            jacobiEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            jacobiEncoder?.endEncoding()

            jacobiEncoder = commandBuffer.makeComputeCommandEncoder()
            jacobiEncoder?.setComputePipelineState(jacobiPipeline)
            jacobiEncoder?.setBytes([-dx * dx], length: MemoryLayout<Float>.stride, index: 0)
            jacobiEncoder?.setBytes([Float(4)], length: MemoryLayout<Float>.stride, index: 1)
            jacobiEncoder?.setTextures([p2, p1, v2], range: 0..<3)
            jacobiEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            jacobiEncoder?.endEncoding()
        }
    }
    
    func projectFinish(commandBuffer: MTLCommandBuffer) {
        let projectFinishEncoder = commandBuffer.makeComputeCommandEncoder()
        projectFinishEncoder?.setComputePipelineState(projectionFinishPipeline)
        projectFinishEncoder?.setTextures([v3, p1, v1], range: 0..<3)
        projectFinishEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        projectFinishEncoder?.endEncoding()
    }
    
    func dye(commandBuffer: MTLCommandBuffer) {
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: dyePipeline,
                               buffers: [],
                               bytes: { _, _ in },
                               textures: [v2, previousDye, dye],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
    }
    func blit(commandBuffer: MTLCommandBuffer, drawingTexture: MTLTexture) {
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: drawingTexture, to: dye)
        blitEncoder?.endEncoding()
    }
    
    func getLocation(event: NSEvent, view: NSView) -> SIMD2<Float>? {
        guard let location = view.window?.contentView?.convert(event.locationInWindow, to: view) else { return nil}
//        return SIMD2<Float>(Float((location.x / view.bounds.size.width) * CGFloat(image.width)), Float((location.y / view.bounds.size.height) * CGFloat(image.height))) / SIMD2(Float(view.bounds.size.width), Float(view.bounds.size.height))
        return SIMD2<Float>(Float((location.x / view.bounds.size.width)), Float((location.y / view.bounds.size.height))) - 0.5
    }
    
    override func mouseDown(event: NSEvent, view: NSView) {
        super.mouseDown(event: event, view: view)
        guard let location = getLocation(event: event, view: view) else { return }
        if !mouseDown {
            lastLocation = location
        }
        currentLocation = location
        mouseDown = true
    }
    
    override func mouseUp(event: NSEvent, view: NSView) {
        super.mouseUp(event: event, view: view)
        mouseDown = false
    }
    
    override func mouseDragged(event: NSEvent, view: NSView) {
        super.mouseDragged(event: event, view: view)
        guard let location = getLocation(event: event, view: view) else { return }
        currentLocation = location
    }
    
    override func mouseMoved(event: NSEvent, view: NSView) {
        super.mouseMoved(event: event, view: view)
        guard let location = getLocation(event: event, view: view) else { return }
        currentLocation = location
    }
}
