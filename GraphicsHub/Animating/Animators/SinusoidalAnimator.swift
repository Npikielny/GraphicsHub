//
//  SinusoidalAnimator.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/12/21.
//

import Cocoa

class SinusoidalAnimator: InputAnimator {
    
    static var name: String = "Sinusoidal"
    var id: Int
    var displayDomain: (Int, Int)? = nil
    var displayRange: (Double, Double)? {
        (intercept - abs(amplitude), intercept + abs(amplitude))
    }
    
    var input: AnimateableInterface
    
    var locus: Double
    var period: Double { didSet { handlePeriod() } }
    private func handlePeriod() {
        if period < 0 {
            period = 0
        }
    }
    var intercept: Double
    
    var amplitude: Double
    
    var manager: AnimatorManager
    
    required init(input: AnimateableInterface, manager: AnimatorManager, index: Int) {
        id = inputIndex
        inputIndex += 1
        self.input = input
        let frameRange = manager.frameRange
        period = Double(frameRange.1 - frameRange.0)
        locus = Double(frameRange.1 + frameRange.0) / 2
        amplitude = 50
        intercept = input.doubleOutput[index]
        self.manager = manager
        handlePeriod()
    }
    
    func getFrame(_ frame: Int) -> Double {
        if period == 0 { return intercept }
        return amplitude * sin((Double(frame) - locus) / period * (2 * Double.pi)) + intercept
    }
    
    func drawPath(_ frame: NSRect) -> NSBezierPath {
        return draw(frameRange: manager.frameRange, frame: frame, points: Int(locus))
    }
    
    func drawPoints(_ frame: NSRect) -> [NSBezierPath] {
        let points: [Int] = Array(manager.frameRange.0...manager.frameRange.1)
        return drawPoints(frameRange: manager.frameRange, frame: frame, pointsList: points)
    }
    
    func getDescription() -> NSString? {
        NSString(utf8String: """
                    Locus: \(locus)
                    Intercept: \(intercept),
                    Amplitude: \(amplitude),
                    Period: \(period)
                    """)
    }
    
    func leftMouseDown(frame: NSRect, location: CGPoint) { }
    
    func leftMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect) {
        if manager.frameRange.1 - manager.frameRange.0 == 0 {
            locus = Double(manager.frameRange.0)
        } else {
            locus = Double(location.x / frame.width * CGFloat(manager.frameRange.1 - manager.frameRange.0))
        }
        intercept -= Double(event.deltaY)
    }
    
    func rightMouseDown(location: CGPoint) {}
    
    func rightMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect) {
        let delta = event.deltaX
        if delta < 0 {
            period -= 0.1
        } else if delta > 0 {
            period += 0.1
        }
        if period < 0 {
            period = 0
        }
        amplitude -= Double(event.deltaY / frame.height) * 50
    }
    
    func scrollWheel(with event: NSEvent) {
        let delta = event.scrollingDeltaX + event.scrollingDeltaY
        if delta < 0 {
            period *= 0.9
        } else if delta > 0 {
            period *= 1.1
        }
        if period < 0 {
            period = 0
        }
    }
    
}
