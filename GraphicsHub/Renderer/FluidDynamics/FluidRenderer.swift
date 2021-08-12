//
//  FluidRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/25/21.
//

import MetalKit

class FluidRenderer: Renderer {
    
    var initializePipeline: MTLComputePipelineState!
    var fluidPipeline: MTLComputePipelineState!
    
    var dt: Float = 0.1
    var diffusionRate: Float = 1
    var viscosity: Float = 1
    
    var density: MTLTexture!
    var velocity: MTLBuffer!
//    var previousVelocitty: MTLTexture!
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: BasicInputManager(imageSize: size), name: "Fluid Renderer")
        let functions = createFunctions("fluidSimulation", "populateVelocities")
        let initializeFunction = functions[1]!
        initializePipeline = try! device.makeComputePipelineState(function: initializeFunction)
        let fluidFunction = functions[0]!
        fluidPipeline = try! device.makeComputePipelineState(function: fluidFunction)
    }
    
    override func drawableSizeDidChange(size: CGSize) {
        super.drawableSizeDidChange(size: size)
        density = createTexture(size: size, editable: true)
        velocity = device.makeBuffer(length: MemoryLayout<SIMD2<Float>>.stride * Int(size.width * size.height), options: .storageModeManaged)
        initialized = false
    }
    
    override func setupResources(commandQueue: MTLCommandQueue?, semaphore: DispatchSemaphore) {
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let populateEncoder = commandBuffer?.makeComputeCommandEncoder()
        populateEncoder?.setComputePipelineState(initializePipeline)
        populateEncoder?.setBytes([size.toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
        populateEncoder?.setBuffer(velocity, offset: 0, index: 1)
        populateEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        populateEncoder?.endEncoding()
        commandBuffer?.commit()
        super.setupResources(commandQueue: commandQueue, semaphore: semaphore)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        
        let fluidEncoder = commandBuffer.makeComputeCommandEncoder()
        fluidEncoder?.setComputePipelineState(fluidPipeline)
        fluidEncoder?.setBytes([inputManager.size().toVector()], length: MemoryLayout<SIMD2<Int32>>.stride, index: 0)
        fluidEncoder?.setBuffer(velocity, offset: 0, index: 1)
        fluidEncoder?.setTexture(image, index: 0)
        fluidEncoder?.setTexture(density, index: 1)
        fluidEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        fluidEncoder?.endEncoding()

        let copyEncoder = commandBuffer.makeBlitCommandEncoder()
        copyEncoder?.copy(from: image, to: density)
        copyEncoder?.synchronize(resource: density)
        copyEncoder?.endEncoding()
        
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
    func addDensity(location: SIMD2<Int>) {
        density.replace(
            region: MTLRegion(origin: MTLOrigin(x: location.x, y: location.y, z: 0), size: MTLSize(width: 1, height: 1, depth: 1)),
            mipmapLevel: 0,
            withBytes: [SIMD4<Float>(0, 1, 0, 0)],
            bytesPerRow: MemoryLayout<SIMD4<Float>>.stride * density.width)
        
    }
    
    
    func addVelocity(location: SIMD2<Int>) {
        memcpy(velocity.contents() + MemoryLayout<SIMD2<Float>>.stride * (location.x + location.y * Int(size.width)), [SIMD2<Float>(1, 1)], MemoryLayout<SIMD2<Float>>.stride)
        velocity.didModifyRange(0..<velocity.length)
    }
    
    func addVelocity(event: NSEvent, view: NSView) {
        guard let location = view.window?.contentView?.convert(event.locationInWindow, to: view) else { return }
        let coordinates = SIMD2<Int>(Int((location.x / view.bounds.size.width) * CGFloat(image.width)), Int((location.y / view.bounds.size.height) * CGFloat(image.height)))
        if coordinates.x >= 0 && coordinates.x < image.width && coordinates.y >= 0 && coordinates.y < image.height {
            addDensity(location: coordinates)
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
