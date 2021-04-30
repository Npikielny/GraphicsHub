//
//  RenderingView.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import MetalKit

class RenderingView: MTKView {
    
    let commandQueue: MTLCommandQueue
    let semaphore = DispatchSemaphore(value: 1)
    
    var renderPipelineState: MTLRenderPipelineState!
    
    var renderer: Renderer?
    
    init(size: CGSize) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to find metal device")
        }
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed command queue")
        }
        self.commandQueue = commandQueue
        
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "copyVertex")!
        let fragmentFunction = library.makeFunction(name: "copyFragment")!
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.sampleCount = 1
        renderDescriptor.vertexFunction = vertexFunction
        renderDescriptor.fragmentFunction = fragmentFunction
        renderDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderDescriptor)
        
        super.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size), device: device)
        
        colorspace = CGColorSpace(name: CGColorSpace.linearSRGB)
        colorPixelFormat = .rgba16Float
        sampleCount = 1
        translatesAutoresizingMaskIntoConstraints = false
        
        self.delegate = self
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setRenderer(renderer: Renderer) {
        if let currentRenderer = self.renderer {
            currentRenderer.inputView?[0].window?.close()
        }
        self.renderer = renderer
        mtkView(self, drawableSizeWillChange: renderer.size)
        self.autoResizeDrawable = renderer.resizeable
        
        if !renderer.resizeable {
            self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: renderer.size.width/renderer.size.height).isActive = true
        }
    }
}

extension RenderingView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard let renderer = renderer else { return }
        renderer.drawableSizeDidChange(size: size)
    }
    
    func draw(in view: MTKView) {
        if let renderPassDescriptor = view.currentRenderPassDescriptor, let renderer = renderer {
            semaphore.wait()
            let commandBuffer = commandQueue.makeCommandBuffer()
            commandBuffer?.addCompletedHandler { _ in self.semaphore.signal() }
            
            if let commandBuffer = commandBuffer {
                renderer.graphicsPipeline(commandBuffer: commandBuffer, view: self)
            }
            
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            if let pipeline = renderer.renderPipelineState {
                renderEncoder?.setRenderPipelineState(pipeline)
            } else {
                renderEncoder?.setRenderPipelineState(renderPipelineState)
            }
            renderEncoder?.setFragmentTexture(renderer.outputImage, index: 0)
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder?.endEncoding()
            
            commandBuffer?.present(view.currentDrawable!)
            commandBuffer?.commit()
            
        }
    }
    
    
}
