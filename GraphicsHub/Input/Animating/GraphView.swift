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
    
}
