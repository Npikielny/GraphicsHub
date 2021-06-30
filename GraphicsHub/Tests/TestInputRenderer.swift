//
//  TestInputRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/20/21.
//

import MetalKit

class TestInputRenderer: Renderer {
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: TestInputManager(size: size), name: "Test Input Renderer")
    }
    
}

class TestInputManager: RendererInputManager {
    
    var imageWidth: CGFloat
    
    var imageHeight: CGFloat
    
    var recording: Bool = false
    var paused: Bool = false
    
    var renderWidth: CGFloat?
    
    var renderHeight: CGFloat?
    
    var inputs: [NSView]
    var animatorManager: AnimatorManager!
    
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
        animatorManager  = AnimatorManager(manager: self)
    }
    
    func handlePerFrameChecks() {
        inputs.forEach({
            if let input = $0 as? InputShell {
                _ = input.didChange
            }
        })
    }
    
    func flagsChanged(event: NSEvent) {}
    
    func keyDown(event: NSEvent) {}
    
    func mouseDown(event: NSEvent) {}
    
    func mouseDragged(event: NSEvent) {}
    
    func mouseMoved(event: NSEvent) {}
    
    func scrollWheel(event: NSEvent) {}
    
    
}
