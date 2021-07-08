//
//  AnimatorManager.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/1/21.
//

import Cocoa

class AnimatorManager {
    
    var frameDomain = (0, 0)
    var animations: [NSView: [InputAnimator]] = [:]
    var window: NSWindow!
    
    init(manager: RendererInputManager) {
        for input in manager.inputs {
            if let inputInterface = input as? AnimateableInterface, inputInterface.animateable {
                var animators = [InputAnimator]()
                for i in 0..<inputInterface.requiredAnimators {
                    animators.append(LinearAnimator(input: inputInterface, manager: self, index: i))
                }
                animations[input] = animators
            }
        }
    }
    
    func setFrame(frame: Int) {
        for (input, animators) in animations {
            if let input = input as? AnimateableInterface {
                let temp = input.didChange
                input.set(animators.map({ $0.getFrame(frame) }), frame: frame)
                input.setDidChange(temp)
            }
        }
    }
    
    func update() {
        
    }
//    func addKeyframe(frame: Int, sender: InputAnimator) {
//        for (input, animators) in animations {
//            if animators.contains(where: { sender.id == $0.id }) {
//                setFrame(frame: frame)
//                (input as? AnimateableInterface)?.addKeyFrame(index: <#T##Int#>, frame: <#T##Int#>, value: <#T##Double#>)
//            }
//        }
//    }
}
