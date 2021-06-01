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
    
    var frameStable: Bool { true }
    var frame: Int = 0
    
    func drawableSizeDidChange(size: CGSize) {
        if inputManager.size() != size {
            drawableSizeDidChange(size: inputManager.size())
            frame = 0
        }
        updateAllInputs()
    }
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        frame += 1
    }
    
    var renderPipelineState: MTLRenderPipelineState?
    
    required init(device: MTLDevice, size: CGSize) {
        self.inputManager = TestInputManager(size: size)
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

class TestInputManager: InputManager {
    
    var imageWidth: CGFloat
    
    var imageHeight: CGFloat
    
    var recording: Bool = false
    var paused: Bool = false
    
    var renderWidth: CGFloat?
    
    var renderHeight: CGFloat?
    
    var inputs: [NSView]
    
    var inputOffset: Int
    
    init(size: CGSize) {
        imageWidth = size.width
        imageHeight = size.height
        inputs = [
            StateInput(name: "Recording"),
            SliderInput(name: "X", minValue: -10, currentValue: 0, maxValue: 10),
            SliderInput(name: "Y", minValue: -10, currentValue: 0, maxValue: 10),
            SizeInput(name: "Size", prefix: nil, minSize: CGSize(width: 0, height: 0), size: CGSize(width: 10, height: 10), maxSize: CGSize(width: 100, height: 100))
        
        ]
        inputOffset = inputs.count
    }
    
    func handlePerFrameChecks() {
        inputs.forEach({
            if let input = $0 as? InputShell {
                _ = input.didChange
            }
        })
    }
    
    func keyDown(event: NSEvent) {}
    
    func mouseDown(event: NSEvent) {}
    
    func mouseDragged(event: NSEvent) {}
    
    func mouseMoved(event: NSEvent) {}
    
    func scrollWheel(event: NSEvent) {}
    
    
}
