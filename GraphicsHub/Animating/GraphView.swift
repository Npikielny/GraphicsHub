//
//  GraphView.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/6/21.
//

import Cocoa

class GraphView: NSView {

    var animators: [InputAnimator]?
    
    var seed: Int = 0
    var editingIndex = 0
    
    private func getColor() -> NSColor {
        seed += 1
        return NSColor(seed: seed)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    var frameController: FrameInterface!
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func mouseEntered(with event: NSEvent) {
        frameController.paused = true
    }
    
    override func mouseExited(with event: NSEvent) {
        frameController.paused = false
    }
    
    var frameDomain: (Int, Int) = (0, 0)
    
    override func mouseMoved(with event: NSEvent) {
        let position = positionInView(event)
        if isMousePoint(position, in: bounds) {
            let frame = Int(position.x / frame.width * CGFloat(frameDomain.1 - frameDomain.0)) + frameDomain.0
            frameController.jumpToFrame(frame)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let path = NSBezierPath()
        path.lineWidth = 3
        NSColor.red.setFill()
        NSColor.red.setStroke()

        let x: CGFloat = (frameDomain.1 - frameDomain.0) == 0 ? frame.width / 2 : frame.width / CGFloat(frameDomain.1 - frameDomain.0) * CGFloat(frameController.frame)
        path.move(to: NSPoint(x: x, y: 0))
        path.line(to: NSPoint(x: x, y: frame.height))

        path.stroke()
        path.fill()
        
        if let animators = animators {
            for animator in animators {
                let path = animator.drawPath(dirtyRect)
                let color = getColor()
                color.setStroke()
                path.stroke()
                let points = animator.drawPoints(dirtyRect)
                color.setFill()
                points.forEach {
                    NSColor.gray.setStroke()
                    $0.stroke()
                    $0.fill()
                }
                let point = animator.drawCurrentPoint(frame: dirtyRect, frameIndex: frameController.frame)
                NSColor.red.setFill()
                color.setStroke()
                point.stroke()
                point.fill()
            }
            if let description = animators[editingIndex].getDescription() {
                description.draw(at: NSPoint(x: 5, y: 5), withAttributes: [
                    .foregroundColor: NSColor.white,
                    .font: NSFont.systemFont(ofSize: 10)
                ])
            }
        }
        seed = 0
    }
    
    func positionInView(_ event: NSEvent) -> NSPoint {
        return convert(event.locationInWindow, from: superview!)
    }
    
    override func mouseDown(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].leftMouseDown(frame: frame, location: positionInView(event))
        }
        display()
    }
    override func mouseDragged(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].leftMouseDragged(with: event, location: positionInView(event), frame: frame)
        }
        display()
    }
    override func rightMouseDown(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].rightMouseDown(frame: frame, location: positionInView(event))
        }
        display()
    }
    override func rightMouseDragged(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].rightMouseDragged(with: event, location: positionInView(event), frame: frame)
        }
        display()
    }
    
    override func scrollWheel(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].scrollWheel(with: event)
        }
        display()
    }
    
}
