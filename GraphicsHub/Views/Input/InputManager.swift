//
//  InputManager.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/4/21.
//

import Cocoa

protocol Inputmanager {
    var imageWidth: Double { get set }
    var imageHeight: Double { get set }
    
    var recording: Bool { get set}
    
    var renderWidth: Double? { get set }
    var renderHeight: Double? { get set }
    
    var inputs: [NSView] { get set }
    var inputOffset: Int { get }
    
    func handlePerFrameChecks()
    
    func keyDown(event: NSEvent)
    func mouseDown(event: NSEvent)
    func mouseMoved(event: NSEvent)
}

extension Inputmanager {
    func size() -> CGSize {
        return CGSize(width: CGFloat(imageWidth), height: CGFloat(imageHeight))
    }
    func getInput(_ renderIndex: Int) -> NSView {
        return inputs[renderIndex + inputOffset]
    }
}

class BasicInputManager: Inputmanager {
    
    var inputOffset: Int
    var imageWidth: Double {
        get { (inputs[0] as! SliderInput).output }
        set { (inputs[0] as! SliderInput).setValue(value: newValue) }
    }
    
    var imageHeight: Double {
        get { (inputs[1] as! SliderInput).output }
        set { (inputs[1] as! SliderInput).setValue(value: newValue) }
    }
    
    var recording: Bool {
        get { (inputs[2] as! StateInput).output }
        set { (inputs[2] as! StateInput).output = newValue }
    }
    
    var renderWidth: Double?
    
    var renderHeight: Double?
    
    var inputs = [NSView]()
    
    init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        inputs.append(SliderInput(name: "Image Width", minValue: 1, currentValue: Double(imageSize?.width ?? 512), maxValue: 2048))
        inputs.append(SliderInput(name: "Image Height", minValue: 1, currentValue: Double(imageSize?.height ?? 512), maxValue: 2048))
        inputs.append(StateInput(name: "Recording"))
        inputOffset = inputs.count
        inputs.append(contentsOf: renderSpecificInputs)
    }
    
    func handlePerFrameChecks() {}
    
    func keyDown(event: NSEvent) {}
    
    func mouseDown(event: NSEvent) {}
    
    func mouseMoved(event: NSEvent) {}
}

class CappedInputManager: Inputmanager {
    
    var inputOffset: Int
    
    private var imageWidthSlider: SliderInput { inputs[0] as! SliderInput }
    var imageWidth: Double {
        get { (inputs[0] as! SliderInput).output }
        set { (inputs[0] as! SliderInput).setValue(value: newValue) }
    }
    
    private var imageHeightSlider: SliderInput { inputs[1] as! SliderInput }
    var imageHeight: Double {
        get { (inputs[1] as! SliderInput).output }
        set { (inputs[1] as! SliderInput).setValue(value: newValue) }
    }
    
    var recording: Bool {
        get { (inputs[2] as! StateInput).output }
        set { (inputs[2] as! StateInput).output = newValue }
    }
    
    private var renderWidthSlider: SliderInput { inputs[3] as! SliderInput }
    var renderWidth: Double? {
        get { (inputs[3] as! SliderInput).output }
        set { (inputs[3] as! SliderInput).setValue(value: newValue!) }
    }
    
    private var renderHeightSlider: SliderInput { inputs[4] as! SliderInput }
    var renderHeight: Double? {
        get { (inputs[4] as! SliderInput).output }
        set { (inputs[4] as! SliderInput).setValue(value: newValue!) }
    }
    
    var inputs = [NSView]()
    
    init(renderSpecificInputs: [NSView], imageSize: CGSize?) {
        inputs.append(SliderInput(name: "Image Width", minValue: 1, currentValue: Double(imageSize?.width ?? 512), maxValue: 2048))
        inputs.append(SliderInput(name: "Image Height", minValue: 1, currentValue: Double(imageSize?.height ?? 512), maxValue: 2048))
        inputs.append(StateInput(name: "Recording"))
        inputs.append(SliderInput(name: "Render Width", minValue: 1, currentValue: Double(min(imageSize?.width ?? 512, 512)), maxValue: 2048))
        inputs.append(SliderInput(name: "Render Height", minValue: 1, currentValue: Double(min(imageSize?.height ?? 512, 512)), maxValue: 2048))
        inputOffset = inputs.count
        inputs.append(contentsOf: renderSpecificInputs)
    }
    
    func handleImageSizeChanges() {
        renderWidthSlider.setValue(value: min(imageWidth, renderWidth!))
        renderHeightSlider.setValue(value: min(imageHeight, renderHeight!))
    }
    
    func handlePerFrameChecks() {
        handleImageSizeChanges()
    }
    
    func keyDown(event: NSEvent) {}
    
    func mouseDown(event: NSEvent) {}
    
    func mouseMoved(event: NSEvent) {}
}

extension CappedInputManager {
    func renderSize() -> CGSize {
        return CGSize(width: CGFloat(renderWidth!), height: CGFloat(renderHeight!))
    }
}
