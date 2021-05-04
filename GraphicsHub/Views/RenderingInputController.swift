//
//  RenderingInputController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import Cocoa

class GeneralInputManager {
    var width: SliderInput { inputs[0] as! SliderInput }
    var height: SliderInput { inputs[1] as! SliderInput }
    
    var size: CGSize { CGSize(width: width.output, height: height.output) }
    
    var recording: Bool = false
    
    var paused: Bool = false
    
    var savingImage: Bool = false
    
    internal func setSize(size: CGSize) {
        width.setValue(value: Double(size.width))
        height.setValue(value: Double(size.height))
    }
    
    func syncSize(size: CGSize) {
        setSize(size: size)
    }
    
    var inputs: [NSView]
    init(inputs: [NSView]) {
        self.inputs = inputs
    }
}

class CappedInputManager: GeneralInputManager {
    var renderWidth: SliderInput { inputs[2] as! SliderInput }
    var renderHeight: SliderInput { inputs[3] as! SliderInput }
    
    var renderSize: CGSize { CGSize(width: renderWidth.output, height: renderHeight.output) }
    
    func syncSize(size: CGSize, renderSize: CGSize) {
        setSize(size: size)
        setRenderSize(size: renderSize)
    }
    
    func setRenderSize(size: CGSize) {
        renderWidth.setValue(value: Double(size.width))
        renderHeight.setValue(value: Double(size.height))
    }
    
}

class RenderingInputController: InputController {

    var rendererType: RendererType = .basic
    private var renderer: Renderer
    init(renderer: Renderer) {
        self.renderer = renderer
        var inputs = [NSView]()
        // Image Size
            // Ray Size
        // Frames per second
        // TODO: FPS
        // Record Button
        // Save Image Button
        // Pause/Play Button
        inputs.append(SliderInput(name: "Image Width", minValue: 1, currentValue: Double(renderer.size.width), maxValue: 4096))
        inputs.append(SliderInput(name: "Image Height", minValue: 1, currentValue: Double(renderer.size.height), maxValue: 4096))
        var inputManager: GeneralInputManager!
        if let renderer = renderer as? CappedRenderer {
            rendererType = .capped
            inputs.append(SliderInput(name: "Render Width", minValue: 1, currentValue: Double(renderer.maxRenderSize.width), maxValue: 4096))
            inputs.append(SliderInput(name: "Render Height", minValue: 1, currentValue: Double(renderer.maxRenderSize.height), maxValue: 4096))
            inputManager = CappedInputManager(inputs: inputs)
        } else {
            inputManager = GeneralInputManager(inputs: inputs)
        }
        self.renderer.inputManager = inputManager
        super.init(inputs: inputs)
//        timer = Timer.scheduledTimer(withTimeInterval: 1/120, repeats: true, block: { _ in
//            if !(self.view.window?.isKeyWindow ?? false) {
//                self.timer.invalidate()
//            }
//            let size = CGSize(width: CGFloat((inputs[0] as! SliderInput).output), height: CGFloat((inputs[1] as! SliderInput).output))
//            if self.renderer.size != size {
//                renderer.drawableSizeDidChange(size: size)
//            }
//            if self.rendererType == .capped {
//                let width = inputs[2] as! SliderInput
//                let height = inputs[3] as! SliderInput
//                let renderSize = CGSize(width: CGFloat((width.output)), height: CGFloat(height.output))
//                var renderer = renderer as! CappedRenderer
//                renderer.setRenderSize(renderSize: renderSize)
//                width.setValue(value: Double(renderer.maxRenderSize.width))
//                height.setValue(value: Double(renderer.maxRenderSize.height))
////
//            }
//        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do view setup here.
//    }
    
}

enum RendererType {
    case basic
    case capped
}
