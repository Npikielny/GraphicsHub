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
    
    var displayRange: (Double, Double)?
    
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
        return draw(frameRange: manager.frameDomain, frame: frame, points: Array(manager.frameDomain.0..<manager.frameDomain.1))
    }
    
    func drawPoints(_ frame: NSRect) -> [NSBezierPath] {
        drawPoints(frameRange: manager.frameDomain, frame: frame, pointsList: input.keyFrames[index].map({$0.0}))
    }
    
    func leftMouseDown(frame: NSRect, location: CGPoint) {
        let position = findPosition(frame: frame, frameRange: manager.frameDomain, position: NSPoint(x: location.x, y: location.y))
        input.addKeyFrame(index: index, frame: position.0, value: position.1)
    }
    
    func leftMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect) {
        
    }
    
    func rightMouseDown(frame: NSRect, location: CGPoint) {
//        let position = findPosition(frame: frame, frameRange: manager.frameDomain, position: NSPoint(x: location.x, y: location.y))
//        let positionInFrame = location
        
        var closest: Int?
        var distance = CGFloat.infinity
        let displayDomain = input.domain[index]
        for (keyFrame, value) in input.keyFrames[index] {
            let newDistance: CGFloat = pow(
                pow(location.x - CGFloat(keyFrame - manager.frameDomain.0) * frame.width / CGFloat(manager.frameDomain.1 - manager.frameDomain.0), 2) +
                    pow(location.y - CGFloat(value)/frame.height * CGFloat(displayDomain.1 - displayDomain.0), 2)
                , 0.5)
            
            // FIXME: Max distance for deletion
            if newDistance < distance { //  && newDistance <= ((frame.width > 100) ? 30 : frame.width * 0.1)
                distance = newDistance
                closest = keyFrame
            }
        }
        print(distance)
        guard let closest = closest else { return }
        input.removeKeyFrame(index: index, frame: closest)
    }
    
    func rightMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect) {}
    
    func scrollWheel(with event: NSEvent) {}
    
    func getDescription() -> NSString? {
        nil
    }
}
