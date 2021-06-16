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
    var editingIndex = 0
    
    private func getColor() -> NSColor {
        seed += 1
        return NSColor(seed: seed)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
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
    
    override func mouseDown(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].leftMouseDown(frame: frame, location: convert(event.locationInWindow, from: superview!))
        }
        self.display()
    }
    override func mouseDragged(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].leftMouseDragged(with: event, location: convert(event.locationInWindow, from: superview!), frame: frame)
        }
        self.display()
    }
    override func rightMouseDown(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].rightMouseDown(frame: frame, location: convert(event.locationInWindow, from: superview!))
        }
        self.display()
    }
    override func rightMouseDragged(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].rightMouseDragged(with: event, location: convert(event.locationInWindow, from: superview!), frame: frame)
        }
        self.display()
    }
    
    override func scrollWheel(with event: NSEvent) {
        if let animators = animators {
            animators[editingIndex].scrollWheel(with: event)
        }
        self.display()
    }
    
}
