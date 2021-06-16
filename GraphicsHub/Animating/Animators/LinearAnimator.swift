//
//  LinearAnimator.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/12/21.
//

import Cocoa

class LinearAnimator: InputAnimator {
    
    static var name: String = "Linear Animator"
    var id: Int
    
    var displayDomain: (Int, Int)?
    
    var input: AnimateableInterface
    var index: Int
    
    var manager: AnimatorManager
    
    required init(input: AnimateableInterface, manager: AnimatorManager, index: Int) {
        id = inputIndex
        inputIndex += 1
        self.input = input
        self.manager = manager
        self.index = index
    }
    
    func getFrame(_ frame: Int) -> Double {
        if let item = input.keyFrames[index].first(where: { $0.0 == frame }) {
            return item.1
        }
        let before = input.keyFrames[index].last(where: { $0.0 < frame })
        let after = input.keyFrames[index].first(where: { $0.0 > frame })
        if before == nil && after == nil {
            return input.doubleOutput![index]
        }
        guard let beforeUnwrapped = before else { return after!.1 }
        guard let afterUnwrapped = after else { return beforeUnwrapped.1 }
        
        let p = Double(frame - beforeUnwrapped.0) / Double(afterUnwrapped.0 - beforeUnwrapped.0)
        return (afterUnwrapped.1 - beforeUnwrapped.1) * p + beforeUnwrapped.1
    }
    
    func drawPath(_ frame: NSRect) -> NSBezierPath {
        let frameRange = displayDomain ?? manager.frameRange
        return draw(frameRange: frameRange, frame: frame, points: Array(frameRange.0..<frameRange.1))
    }
    
    func drawPoints(_ frame: NSRect) -> [NSBezierPath] {
        drawPoints(frameRange: displayDomain ?? manager.frameRange, frame: frame, pointsList: input.keyFrames[index].map({$0.0}))
    }
    
    func leftMouseDown(frame: NSRect, location: CGPoint) {
        let position = findPosition(frame: frame, frameRange: (displayDomain) ?? manager.frameRange, position: NSPoint(x: location.x, y: location.y))
        input.addKeyFrame(index: index, frame: position.0, value: position.1)
    }
    
    func leftMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect) {
        
    }
    
    func rightMouseDown(frame: NSRect, location: CGPoint) {
        let position = findPosition(frame: frame, frameRange: (displayDomain) ?? manager.frameRange, position: NSPoint(x: location.x, y: location.y))
        input.removeKeyFrame(index: index, frame: position.0)
    }
    
    func rightMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect) {}
    
    func scrollWheel(with event: NSEvent) {}
    
    func getDescription() -> NSString? {
        nil
    }
}
