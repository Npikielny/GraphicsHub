//
//  RendererInputManager.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/7/21.
//

import Cocoa

protocol RendererInputManager: FrameInterface {
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
    
    var frame: Int { get set }
    func jumpToFrame(_ frame: Int)
    
    func handlePerFrameChecks()
    
    func flagsChanged(event: NSEvent)
    func keyDown(event: NSEvent)
    func mouseDown(event: NSEvent)
    func rightMouseDown(event: NSEvent)
    func mouseDragged(event: NSEvent)
    func rightMouseDragged(event: NSEvent)
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
    
    var frame: Int = 0
    
    init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        inputs.append(ScreenSizeInput(name: "Image Size", minSize: CGSize(width: 1, height: 1), size: CGSize(width: 3840, height: 2160)))
        inputs.append(StateInput(name: "Recording"))
        inputs.append(StateInput(name: "Paused", integralRenderingSetting: false))
        inputs.append(SliderInput(name: "Frames Per Recording Frame", minValue: 1, currentValue: 1, maxValue: 50, tickMarks: 50, animateable: false))
        inputOffset = inputs.count
        inputs.append(contentsOf: renderSpecificInputs)
        animatorManager = AnimatorManager(manager: self)
    }
    
    func jumpToFrame(_ frame: Int) {
        self.frame = frame
        animatorManager.setFrame(frame: frame)
        recording = false
    }
    
    func handlePerFrameChecks() {}
    
    func flagsChanged(event: NSEvent) {}
    func keyDown(event: NSEvent) {}
    func mouseDown(event: NSEvent) {}
    func rightMouseDown(event: NSEvent) {}
    func mouseDragged(event: NSEvent) {}
    func rightMouseDragged(event: NSEvent) {}
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
    
    var frame: Int = 0
    internal var intermediateFrame: Int = 0
    
    init(renderSpecificInputs: [NSView], imageSize: CGSize?) {
        inputs.append(ScreenSizeInput(name: "Image Size", size: CGSize(width: 3840, height: 2160)))
        inputs.append(SizeInput(name: "Render Size", prefix: "Render", minSize: CGSize(width: 1, height: 1), size: CGSize(width: 512, height: 512), maxSize: CGSize(width: 4096, height: 4096)))
        inputs.append(StateInput(name: "Recording"))
        inputs.append(StateInput(name: "Paused", integralRenderingSetting: false))
        inputs.append(SliderInput(name: "Frames Per Recording Frame", minValue: 1, currentValue: 1, maxValue: 50, tickMarks: 50, animateable: false))
        inputOffset = inputs.count
        inputs.append(contentsOf: renderSpecificInputs)
        animatorManager = AnimatorManager(manager: self)
    }
    
    func jumpToFrame(_ frame: Int) {
        self.frame = frame
        intermediateFrame = 0
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
    func rightMouseDown(event: NSEvent) {}
    func mouseDragged(event: NSEvent) {}
    func rightMouseDragged(event: NSEvent) {}
    func mouseMoved(event: NSEvent) {}
    func scrollWheel(event: NSEvent) {}
}

extension CappedInputManager {
    func computeSize() -> CGSize {
        return CGSize(width: CGFloat(renderWidth!), height: CGFloat(renderHeight!))
    }
}

class AntialiasingInputManager: CappedInputManager {
    var renderPassesPerFrame: Int {
        Int((inputs[5] as! SliderInput).output)
    }
    var renderPasses = 0
    
    override init(renderSpecificInputs: [NSView], imageSize: CGSize?) {
        let renderPasses = SliderInput(name: "Passes", minValue: 1, currentValue: 5, maxValue: 1000, tickMarks: 101)
        super.init(renderSpecificInputs: [renderPasses] + renderSpecificInputs, imageSize: imageSize)
        inputOffset += 1
    }
    
    override func jumpToFrame(_ frame: Int) {
        super.jumpToFrame(frame)
        renderPasses = 0
    }
    
}
