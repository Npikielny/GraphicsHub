//
//  RendererInputManager.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/7/21.
//

import Cocoa

protocol RendererInputManager {
    var inputOffset: Int { get }
    
    var imageWidth: CGFloat { get set }
    var imageHeight: CGFloat { get set }
    
    var recording: Bool { get set}
    var paused: Bool { get set }
    
    var renderWidth: CGFloat? { get set }
    var renderHeight: CGFloat? { get set }
    
    var framesPerFrame: Int { get set }
    
    var animatorManager: AnimatorManager! { get set }
    
    var inputs: [NSView] { get set }
    
    func handlePerFrameChecks()
    
    func flagsChanged(event: NSEvent)
    func keyDown(event: NSEvent)
    func mouseDown(event: NSEvent)
    func mouseDragged(event: NSEvent)
    func mouseMoved(event: NSEvent)
    func scrollWheel(event: NSEvent)
}

extension RendererInputManager {
    func size() -> CGSize {
        return CGSize(width: CGFloat(imageWidth), height: CGFloat(imageHeight))
    }
    func getInput(_ renderIndex: Int) -> NSView {
        return inputs[renderIndex + inputOffset]
    }
}

class BasicInputManager: RendererInputManager {
    
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
    
    var paused: Bool {
        get { (inputs[2] as! StateInput).output }
        set { (inputs[2] as! StateInput).output = newValue }
    }
    
    var framesPerFrame: Int {
        get { Int((inputs[3] as! SliderInput).output) }
        set { (inputs[3] as! SliderInput).setValue(value: Double(newValue)) }
    }
    
    var renderWidth: CGFloat?
    
    var renderHeight: CGFloat?
    
    var inputs = [NSView]()
    var animatorManager: AnimatorManager!
    
    init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        inputs.append(ScreenSizeInput(name: "Image Size", minSize: CGSize(width: 1, height: 1), size: CGSize(width: 3840, height: 2160)))
        inputs.append(StateInput(name: "Recording"))
        inputs.append(StateInput(name: "Paused"))
        inputs.append(SliderInput(name: "Frames Per Recording Frame", minValue: 1, currentValue: 1, maxValue: 50, tickMarks: 50, animateable: false))
        inputOffset = inputs.count
        inputs.append(contentsOf: renderSpecificInputs)
        animatorManager = AnimatorManager(manager: self)
    }
    
    func handlePerFrameChecks() {}
    
    func flagsChanged(event: NSEvent) {}
    func keyDown(event: NSEvent) {}
    func mouseDown(event: NSEvent) {}
    func mouseDragged(event: NSEvent) {}
    func mouseMoved(event: NSEvent) {}
    func scrollWheel(event: NSEvent) {}
    
}

class CappedInputManager: RendererInputManager {
    
    var inputOffset: Int
    
    var imageWidth: CGFloat {
        get { (inputs[0] as! ScreenSizeInput).width }
        set { (inputs[0] as! ScreenSizeInput).width = newValue }
    }
    
    var imageHeight: CGFloat {
        get { (inputs[0] as! ScreenSizeInput).height }
        set { (inputs[0] as! ScreenSizeInput).height = newValue }
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
    var paused: Bool {
        get { (inputs[3] as! StateInput).output }
        set { (inputs[3] as! StateInput).output = newValue }
    }
    
    var framesPerFrame: Int {
        get { Int((inputs[4] as! SliderInput).output) }
        set { (inputs[4] as! SliderInput).setValue(value: Double(newValue)) }
    }
    
    var inputs = [NSView]()
    var animatorManager: AnimatorManager!
    
    init(renderSpecificInputs: [NSView], imageSize: CGSize?) {
        inputs.append(ScreenSizeInput(name: "Image Size", size: CGSize(width: 3840, height: 2160)))
        inputs.append(SizeInput(name: "Render Size", prefix: "Render", minSize: CGSize(width: 1, height: 1), size: CGSize(width: 512, height: 512), maxSize: CGSize(width: 4096, height: 4096)))
        inputs.append(StateInput(name: "Recording"))
        inputs.append(StateInput(name: "Paused"))
        inputs.append(SliderInput(name: "Frames Per Recording Frame", minValue: 1, currentValue: 1, maxValue: 50, tickMarks: 50))
        inputOffset = inputs.count
        inputs.append(contentsOf: renderSpecificInputs)
        animatorManager = AnimatorManager(manager: self)
    }
    
    func handleImageSizeChanges() {
        let renderSize = inputs[1] as! SizeInput
        renderSize.width = min(imageWidth, renderWidth!)
        renderSize.height = min(imageHeight, renderHeight!)
    }
    
    func handlePerFrameChecks() {
        handleImageSizeChanges()
    }
    
    func flagsChanged(event: NSEvent) {}
    func keyDown(event: NSEvent) {}
    func mouseDown(event: NSEvent) {}
    func mouseDragged(event: NSEvent) {}
    func mouseMoved(event: NSEvent) {}
    func scrollWheel(event: NSEvent) {}
}

extension CappedInputManager {
    func computeSize() -> CGSize {
        return CGSize(width: CGFloat(renderWidth!), height: CGFloat(renderHeight!))
    }
}

class AntialiasingInputManager: CappedInputManager {
    var renderPasses: Int {
        Int((inputs[5] as! SliderInput).output)
    }
    
    override init(renderSpecificInputs: [NSView], imageSize: CGSize?) {
        let renderPasses = SliderInput(name: "Passes", minValue: 1, currentValue: 10, maxValue: 100, tickMarks: 100)
        super.init(renderSpecificInputs: [renderPasses] + renderSpecificInputs, imageSize: imageSize)
        inputOffset += 1
    }
}
