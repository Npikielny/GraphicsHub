//
//  InputManager.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/4/21.
//

import Cocoa

protocol InputManager {
    var imageWidth: CGFloat { get set }
    var imageHeight: CGFloat { get set }
    
    var recording: Bool { get set}
    
    var renderWidth: CGFloat? { get set }
    var renderHeight: CGFloat? { get set }
    
    var inputs: [NSView] { get set }
    var inputOffset: Int { get }
    
    func handlePerFrameChecks()
    
    func keyDown(event: NSEvent)
    func mouseDown(event: NSEvent)
    func mouseDragged(event: NSEvent)
    func mouseMoved(event: NSEvent)
    func scrollWheel(event: NSEvent)
}

extension InputManager {
    func size() -> CGSize {
        return CGSize(width: CGFloat(imageWidth), height: CGFloat(imageHeight))
    }
    func getInput(_ renderIndex: Int) -> NSView {
        return inputs[renderIndex + inputOffset]
    }
}

class BasicInputManager: InputManager {
    
    var inputOffset: Int
    var imageWidth: CGFloat {
        get { (inputs[0] as! SizeInput).width }
        set { (inputs[0] as! SizeInput).width = newValue }
    }
    
    var imageHeight: CGFloat {
        get { (inputs[0] as! SizeInput).height }
        set { (inputs[0] as! SizeInput).height = newValue }
    }
    
    var recording: Bool {
        get { (inputs[1] as! StateInput).output }
        set { (inputs[1] as! StateInput).output = newValue }
    }
    
    var renderWidth: CGFloat?
    
    var renderHeight: CGFloat?
    
    var inputs = [NSView]()
    
    init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        inputs.append(ScreenSizeInput(name: "Image Size", minSize: CGSize(width: 1, height: 1), size: CGSize(width: 2048, height: 2048)))
        inputs.append(StateInput(name: "Recording"))
        inputOffset = inputs.count
        inputs.append(contentsOf: renderSpecificInputs)
    }
    
    func handlePerFrameChecks() {}
    func keyDown(event: NSEvent) {}
    func mouseDown(event: NSEvent) {}
    func mouseDragged(event: NSEvent) {}
    func mouseMoved(event: NSEvent) {}
    func scrollWheel(event: NSEvent) {}
    
}

class CappedInputManager: InputManager {
    
    var inputOffset: Int
    
//    private var imageWidthSlider: SliderInput { inputs[0] as! SliderInput }
    var imageWidth: CGFloat {
        get { (inputs[0] as! ScreenSizeInput).width }
        set { (inputs[0] as! ScreenSizeInput).width = newValue }
    }
    
    var imageHeight: CGFloat {
        get { (inputs[0] as! SizeInput).height }
        set { (inputs[0] as! SizeInput).height = newValue }
    }
    
    var renderWidth: CGFloat? {
        get { (inputs[1] as! SizeInput).width }
        set { (inputs[1] as! SizeInput).width = newValue! }
    }
    
    var renderHeight: CGFloat? {
        get { (inputs[1] as! SizeInput).height }
        set { (inputs[1] as! SizeInput).height = newValue! }
    }
    var recording: Bool {
        get { (inputs[2] as! StateInput).output }
        set { (inputs[2] as! StateInput).output = newValue }
    }
    var inputs = [NSView]()
    
    init(renderSpecificInputs: [NSView], imageSize: CGSize?) {
        inputs.append(ScreenSizeInput(name: "Image Size", size: CGSize(width: 2048, height: 2048)))
        inputs.append(SizeInput(name: "Render Size", prefix: "Render", minSize: CGSize(width: 1, height: 1), size: CGSize(width: 512, height: 512), maxSize: CGSize(width: 4096, height: 4096)))
        inputs.append(StateInput(name: "Recording"))
        inputOffset = inputs.count
        inputs.append(contentsOf: renderSpecificInputs)
    }
    
    func handleImageSizeChanges() {
        let renderSize = inputs[1] as! SizeInput
        renderSize.width = min(imageWidth, renderWidth!)
        renderSize.height = min(imageHeight, renderHeight!)
    }
    
    func handlePerFrameChecks() {
        handleImageSizeChanges()
    }
    
    func keyDown(event: NSEvent) {}
    func mouseDown(event: NSEvent) {}
    func mouseDragged(event: NSEvent) {}
    func mouseMoved(event: NSEvent) {}
    func scrollWheel(event: NSEvent) {}
}

extension CappedInputManager {
    func renderSize() -> CGSize {
        return CGSize(width: CGFloat(renderWidth!), height: CGFloat(renderHeight!))
    }
}
