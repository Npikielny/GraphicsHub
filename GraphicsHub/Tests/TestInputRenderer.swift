//
//  TestInputRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/20/21.
//

import MetalKit

class TestInputRenderer: Renderer {
    var name: String = "Test Input Renderer"
    
    var device: MTLDevice
    
    var renderSpecificInputs: [NSView]?
    
    var inputManager: InputManager
    
    func synchronizeInputs() {
        inputManager.handlePerFrameChecks()
    }
    
    var size: CGSize
    
    var recordable: Bool = true
    
    var recordPipeline: MTLComputePipelineState!
    
    var outputImage: MTLTexture!
    
    var resizeable: Bool = false
    
    func drawableSizeDidChange(size: CGSize) {
        if inputManager.size() != size {
            drawableSizeDidChange(size: inputManager.size())
        }
    }
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {}
    
    var renderPipelineState: MTLRenderPipelineState?
    
    required init(device: MTLDevice, size: CGSize) {
        self.inputManager = TestInputManager(imageSize: size)
        self.device = device
        self.size = size
        
        guard let texture = createTexture(size: size) else {
            fatalError("Failed to create texture")
        }
        self.outputImage = texture
    }
    
    var url: URL?
    
    func getDirectory(frameIndex: Int) throws -> URL {
        fatalError()
    }
    
    
}

class TestInputManager: BasicInputManager {
    
}
