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
        vectorJacobiPipeline,
        scalarJacobiPipeline,
        forcePipeline,
        colorPipeline,
        projectionSetupPipeline,
        projectionFinishPipeline,
        dyePipeline: MTLComputePipelineState!
    
    var dt: Float {
        let inputManager = inputManager as! FluidInputManager
        return inputManager.dt
    }
    var diffusionRate: Float {
        let inputManager = inputManager as! FluidInputManager
        return inputManager.diffusionRate
    }
    var time: Float = 0
    
    var p1: MTLTexture!
    var p2: MTLTexture!
    var v1: MTLTexture!
    var v2: MTLTexture!
    var v3: MTLTexture!
    var previousDye: MTLTexture!
    var dye: MTLTexture { outputImage }
    // image is ink texture
    
    var lastLocation: SIMD2<Float> = SIMD2(0, 0)
    var currentLocation: SIMD2<Float> = SIMD2(0, 0)
    var mouseDown = false
    
    var dx: Float { 1 / Float(resolutionY) }
    var viscosity: Float {
        let inputManager = inputManager as! FluidInputManager
        return inputManager.viscosity
    }
    var alpha: Float { dx * dx / (Float(viscosity) * dt); }
    var beta: Float { 4 + alpha }
    
    var seed: Int32 = 0
    
    override func synchronizeInputs() {
        let inputManager = inputManager as! FluidInputManager
        if (inputManager.getInput(0) as! InputShell).didChange {
            createTextures()
        }
        super.synchronizeInputs()
    }
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: FluidInputManager(imageSize: size), name: "Fluid Renderer")
        let functions = createFunctions("initialize", "advect", "jacobiVector", "jacobiScalar", "force", "projectionSetup", "projectionFinish", "moveDye", "addColor")
        initializePipeline = try! device.makeComputePipelineState(function: functions[0]!)
        advectPipeline = try! device.makeComputePipelineState(function: functions[1]!)
        vectorJacobiPipeline = try! device.makeComputePipelineState(function: functions[2]!)
        scalarJacobiPipeline = try! device.makeComputePipelineState(function: functions[3]!)
        forcePipeline = try! device.makeComputePipelineState(function: functions[4]!)
        projectionSetupPipeline = try! device.makeComputePipelineState(function: functions[5]!)
        projectionFinishPipeline = try! device.makeComputePipelineState(function: functions[6]!)
        dyePipeline = try! device.makeComputePipelineState(function: functions[7]!)
        colorPipeline = try! device.makeComputePipelineState(function: functions[8]!)
        inputManager.paused = true
    }
    
    override func drawableSizeDidChange(size: CGSize) {
        super.drawableSizeDidChange(size: size)
        previousDye = createTexture(size: size)
        createTextures()
        frame = 0
    }
    
    func createTextures() {
        let inputManager = inputManager as! FluidInputManager
        let size = CGSize(width: inputManager.computeSize, height: Int(Float(size.height / size.width) * Float(inputManager.computeSize)))
        p1 = createTexture(size: size)
        p2 = createTexture(size: size)
        v1 = createTexture(size: size)
        v2 = createTexture(size: size)
        v3 = createTexture(size: size)
        initialized = false
    }
    
    override func setupResources(commandQueue: MTLCommandQueue?, semaphore: DispatchSemaphore) {
        time = 0
        seed = Int32(Int.random(in: 0...99999))
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
    
    var resolutionY: Int { getImageGroupSize(texture: v1).height * 8 }
    var resolutionX: Int { getImageGroupSize(texture: v1).width * 8 }
    
    
    func drawMouse() {
        lastLocation = currentLocation
        mouseDown = true
        let t = Float(frame) / 3000 * Float.pi * 2
        currentLocation = SIMD2<Float>(cos(5 * t), sin(7 * t)) / 2 * 0.9
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        // advect
        advect(commandBuffer: commandBuffer)
         // jacobi 2
        jacobi2(commandBuffer: commandBuffer)
        // set force
        force(commandBuffer: commandBuffer)
        // project setup
        projectSetup(commandBuffer: commandBuffer)
        // jacobi 1
        jacobi1(commandBuffer: commandBuffer)
        // project finish
        projectFinish(commandBuffer: commandBuffer)
//        // dye?
////        blit(commandBuffer: commandBuffer, drawingTexture: v2)
        dye(commandBuffer: commandBuffer, drawingTexture: v1)
        
        time += dt
        // synchronize?
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: dye, to: previousDye)
        blitEncoder?.endEncoding()
        lastLocation = currentLocation
        super.draw(commandBuffer: commandBuffer, view: view)
        
        drawMouse()
    }
    
    func advect(commandBuffer: MTLCommandBuffer) {
        let advectEncoder = commandBuffer.makeComputeCommandEncoder()
        advectEncoder?.setComputePipelineState(advectPipeline)
        advectEncoder?.setBytes([dt], length: MemoryLayout<Float>.stride, index: 0)
        advectEncoder?.setTextures([v1, v2], range: 0..<2)
        advectEncoder?.dispatchThreadgroups(getImageGroupSize(texture: v1), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        advectEncoder?.endEncoding()
        
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: v2, to: v1)
        blitEncoder?.endEncoding()
    }
    
    func jacobi2(commandBuffer: MTLCommandBuffer) {
        for _ in 0..<20 {
            // jacobi
            var jacobiEncoder = commandBuffer.makeComputeCommandEncoder()
            jacobiEncoder?.setComputePipelineState(vectorJacobiPipeline)
            jacobiEncoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: 0)
            jacobiEncoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: 1)
            jacobiEncoder?.setTextures([v2, v3, v1], range: 0..<3)
            jacobiEncoder?.dispatchThreadgroups(getImageGroupSize(texture: v1), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            jacobiEncoder?.endEncoding()
            
            jacobiEncoder = commandBuffer.makeComputeCommandEncoder()
            jacobiEncoder?.setComputePipelineState(vectorJacobiPipeline)
            jacobiEncoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: 0)
            jacobiEncoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: 1)
            jacobiEncoder?.setTextures([v3, v2, v1], range: 0..<3)
            jacobiEncoder?.dispatchThreadgroups(getImageGroupSize(texture: v1), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
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
        let forceVector = (currentLocation - lastLocation) * (mouseDown ? 300 : 0)
        let forceEncoder = commandBuffer.makeComputeCommandEncoder()
        forceEncoder?.setComputePipelineState(forcePipeline)
        forceEncoder?.setBytes([forceVector], length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
        forceEncoder?.setBytes([currentLocation], length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
        forceEncoder?.setBytes([Float(200)], length: MemoryLayout<Float>.stride, index: 2)
        forceEncoder?.setTextures([v2, v3], range: 0..<2)
        forceEncoder?.dispatchThreadgroups(getImageGroupSize(texture: v2), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1)) // change dispatch size?
        forceEncoder?.endEncoding()
        
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: colorPipeline,
                               buffers: [],
                               bytes: { [self] encoder, _ in
                                encoder?.setBytes([currentLocation], length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
                                encoder?.setBytes([forceVector], length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
                                encoder?.setBytes([Float(200)], length: MemoryLayout<Float>.stride, index: 2)
                                encoder?.setBytes([Int32(frame)], length: MemoryLayout<Int32>.stride, index: 3)
                                encoder?.setBytes([seed], length: MemoryLayout<Int32>.stride, index: 4)
                               },
                               textures: [previousDye],
                               threadGroups: getImageGroupSize(),
                               threadGroupSize: MTLSize(width: 8, height: 8, depth: 1))
    }
    
    func projectSetup(commandBuffer: MTLCommandBuffer) {
        let projectionSetupEncoder = commandBuffer.makeComputeCommandEncoder()
        projectionSetupEncoder?.setComputePipelineState(projectionSetupPipeline)
        projectionSetupEncoder?.setTextures([v3, v2, p1], range: 0..<3)
        projectionSetupEncoder?.dispatchThreadgroups(getImageGroupSize(texture: p1), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        projectionSetupEncoder?.endEncoding()
    }
    
    func jacobi1(commandBuffer: MTLCommandBuffer) {
        let alpha = -dx * dx
        let beta: Float = 4
        for _ in 0..<20 {
            var jacobiEncoder = commandBuffer.makeComputeCommandEncoder()
            jacobiEncoder?.setComputePipelineState(scalarJacobiPipeline)
            jacobiEncoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: 0)
            jacobiEncoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: 1)
            jacobiEncoder?.setTextures([p1, p2, v2], range: 0..<3)
            jacobiEncoder?.dispatchThreadgroups(getImageGroupSize(texture: v2), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            jacobiEncoder?.endEncoding()

            jacobiEncoder = commandBuffer.makeComputeCommandEncoder()
            jacobiEncoder?.setComputePipelineState(scalarJacobiPipeline)
            jacobiEncoder?.setBytes([alpha], length: MemoryLayout<Float>.stride, index: 0)
            jacobiEncoder?.setBytes([beta], length: MemoryLayout<Float>.stride, index: 1)
            jacobiEncoder?.setTextures([p2, p1, v2], range: 0..<3)
            jacobiEncoder?.dispatchThreadgroups(getImageGroupSize(texture: v2), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            jacobiEncoder?.endEncoding()
        }
    }
    
    func projectFinish(commandBuffer: MTLCommandBuffer) {
        let projectFinishEncoder = commandBuffer.makeComputeCommandEncoder()
        projectFinishEncoder?.setComputePipelineState(projectionFinishPipeline)
        projectFinishEncoder?.setTextures([v3, p1, v1], range: 0..<3)
        projectFinishEncoder?.dispatchThreadgroups(getImageGroupSize(texture: v1), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        projectFinishEncoder?.endEncoding()
    }
    
    func dye(commandBuffer: MTLCommandBuffer, drawingTexture: MTLTexture) {
        dispatchComputeEncoder(commandBuffer: commandBuffer,
                               computePipeline: dyePipeline,
                               buffers: [],
                               bytes: { [self] encoder, offset in
                                encoder?.setBytes([dt], length: MemoryLayout<Float>.stride, index: offset)
                                encoder?.setBytes([diffusionRate], length: MemoryLayout<Float>.stride, index: offset + 1)
                               },
                               textures: [drawingTexture, previousDye, dye],
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
    
//    override func mouseDown(event: NSEvent, view: NSView) {
//        super.mouseDown(event: event, view: view)
//        guard let location = getLocation(event: event, view: view) else { return }
//        if !mouseDown {
//            lastLocation = location
//        }
//        currentLocation = location
//        mouseDown = true
//    }
//
//    override func mouseUp(event: NSEvent, view: NSView) {
//        super.mouseUp(event: event, view: view)
//        mouseDown = false
//    }
//
//    override func mouseDragged(event: NSEvent, view: NSView) {
//        super.mouseDragged(event: event, view: view)
//        guard let location = getLocation(event: event, view: view) else { return }
//        currentLocation = location
//    }
//
//    override func mouseMoved(event: NSEvent, view: NSView) {
//        super.mouseMoved(event: event, view: view)
//        guard let location = getLocation(event: event, view: view) else { return }
//        currentLocation = location
//    }
}

class FluidInputManager: BasicInputManager {
    var computeSize: Int {
        Int((getInput(0) as! SliderInput).output)
    }
    
    var dt: Float {
        Float((getInput(1) as! SliderInput).output)
    }
    
    var viscosity: Float {
        pow(10, Float((getInput(2) as! SliderInput).output))
    }
    
    var diffusionRate: Float {
        Float((getInput(3) as! SliderInput).output)
    }
    
    override init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        let computeSize = SliderInput(name: "Compute Size", minValue: 128, currentValue: 512, maxValue: 1024, tickMarks: 8)
        let dt = SliderInput(name: "Increment", minValue: 0.000001, currentValue: 0.001, maxValue: 0.1)
        let viscosity = SliderInput(name: "Viscosity", minValue: -30, currentValue: -6, maxValue: 10)
        let diffusionRate = SliderInput(name: "Diffusion Rate", minValue: 0, currentValue: 0.1, maxValue: 1)
        super.init(renderSpecificInputs: [computeSize, dt, viscosity, diffusionRate] + renderSpecificInputs, imageSize: imageSize)
    }
    
    
}
