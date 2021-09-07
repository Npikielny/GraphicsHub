//
//  AnimatorManager.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/1/21.
//

import Cocoa

protocol FrameInterface {
    var frame: Int { get set }
    var paused: Bool { get set }
    func jumpToFrame(_ frame: Int)
}

class AnimatorManager {
    
    var frameDomain = (0, 0) {
        didSet {
            graphView?.frameDomain = frameDomain
        }
    }
    var animations: [NSView: [InputAnimator]] = [:]
    var window: NSWindow!
    
    var frameController: FrameInterface!
    var graphView: GraphView?
    
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
        frameController.frame = frame
        for (input, animators) in animations {
            if let input = input as? AnimateableInterface {
                let temp = input.didChange
                if temp {
                    if let animateable = temp as? AnimateableInterface {
                        if animateable.keyFrames.count > 0 {
                            animateable.addCurrentKeyFrame(currentFrame: frame)
                        }
                    }
                }
                
                input.set(animators.map({ $0.getFrame(frame) }), frame: frame)
                input.setDidChange(temp)
            }
        }
    }
    
    func drawGraphs() {
        if graphView?.window?.isKeyWindow ?? false {
            graphView?.display()
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
