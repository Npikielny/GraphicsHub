//
//  AnimatorManager.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/1/21.
//

import Cocoa

class AnimatorManager {
    
    var frameRange = (0, 10)
    var animations: [NSView: [InputAnimator]] = [:]
    var window: NSWindow!
    
    init(manager: RendererInputManager) {
        for input in manager.inputs {
            if let inputInterface = input as? AnimateableInterface {
                animations[input] = Array(repeating: SinusoidalAnimator(input: inputInterface, manager: self), count: inputInterface.requiredAnimators)
            }
        }
        print(animations)
    }
    
    func setFrame(frame: Int) {
        for (input, animators) in animations {
            if let input = input as? AnimateableInterface {
                input.set(animators.map({ $0.getFrame(frame) }))
            }
        }
    }
    
}
