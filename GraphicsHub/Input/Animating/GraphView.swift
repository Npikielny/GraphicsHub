//
//  GraphView.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/6/21.
//

import Cocoa

class GraphView: NSView {

    override var acceptsFirstResponder: Bool { true }
    
    var animators: [InputAnimator]?
    
    var seed: Int = 0
    
    private func getColor() -> NSColor {
        seed += 1
        return NSColor(seed: seed)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if let animators = animators {
            for (index, animator) in animators.enumerated() {
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
                if index == 0 {
                    if let description = animator.getDescription() {
                        description.draw(at: NSPoint(x: 5, y: 5), withAttributes: [
                            .foregroundColor: NSColor.white,
                            .font: NSFont.systemFont(ofSize: 10)
                        ])
                    }
                }
            }
        }
//        for i in 0...10 {
//            let path = NSBezierPath()
//            path.move(to: NSPoint(x: 0, y: 0))
//            path.line(to: NSPoint(x: 100, y: i * 109))
//            path.lineWidth = 3
//            getColor().setStroke()
//            path.stroke()
//        }
        
        seed = 0
    }
    
    override func mouseDown(with event: NSEvent) {}
    override func mouseDragged(with event: NSEvent) {
        if let animators = animators {
            animators.forEach {
                $0.leftMouseDragged(with: event, location: convert(event.locationInWindow, from: superview!), frame: frame)
            }
        }
        self.display()
    }
    override func rightMouseDown(with event: NSEvent) {}
    override func rightMouseDragged(with event: NSEvent) {
        if let animators = animators {
            animators.forEach {
                $0.rightMouseDragged(with: event, location: convert(event.locationInWindow, from: superview!), frame: frame)
            }
        }
        self.display()
    }
    
    override func scrollWheel(with event: NSEvent) {
        if let animators = animators {
            animators.forEach {
                $0.scrollWheel(with: event)
            }
        }
        self.display()
    }
    
}
