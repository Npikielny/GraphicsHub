//
//  SinusoidalAnimator.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/12/21.
//

import Cocoa

class SinusoidalAnimator: InputAnimator {
    
    static var name: String { "Sinusoidal" }
    var id: Int
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
    var intercept: Double {
        didSet {
            intercept = intercept < input.domain[index].0 ? input.domain[index].0 : intercept
            intercept = intercept > input.domain[index].1 ? input.domain[index].1 : intercept
        }
    }
    var amplitude: Double {
        didSet {
            if abs(amplitude) + intercept > input.domain[index].1 {
                amplitude = (input.domain[index].1 - intercept) * (amplitude < 0 ? -1 : 1)
            }else if abs(amplitude) + intercept < input.domain[index].0 {
                amplitude = (intercept - input.domain[index].0) * (amplitude < 0 ? -1 : 1)
            }
        }
    }
    
    var index: Int
    var manager: AnimatorManager
    
    required init(input: AnimateableInterface, manager: AnimatorManager, index: Int) {
        id = inputIndex
        inputIndex += 1
        self.index = index
        self.input = input
        let frameRange = manager.frameDomain
        period = Double(frameRange.1 - frameRange.0)
        locus = Double(frameRange.1 + frameRange.0) / 2
        amplitude = (input.domain[index].1 - input.domain[index].0) / 2
        intercept = (input.domain[index].1 + input.domain[index].0) / 2
        self.manager = manager
        handlePeriod()
    }
    
    func getFrame(_ frame: Int) -> Double {
        if period == 0 { return intercept }
        return amplitude * sin((Double(frame) - locus) / period * (2 * Double.pi)) + intercept
    }
    
    func drawPath(_ frame: NSRect) -> NSBezierPath {
        return draw(frameRange: manager.frameDomain, frame: frame, points: Int(locus))
    }
    
    func drawPoints(_ frame: NSRect) -> [NSBezierPath] {
        
        // FIXME: Some optimization for drawing high point count
//        let points: [Int] = manager.frameRange.1 - manager.frameRange.0 + 1 > 100 ?
//            Array(0...100).map { (manager.frameRange.1 - manager.frameRange.0) * $0 / 100 + manager.frameRange.0 } :
//            Array(manager.frameRange.0...manager.frameRange.1)
        let points = Array(manager.frameDomain.0...manager.frameDomain.1)
        return drawPoints(frameRange: manager.frameDomain, frame: frame, pointsList: points)
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
        if manager.frameDomain.1 - manager.frameDomain.0 == 0 {
            locus = Double(manager.frameDomain.0)
        } else {
            locus = Double(location.x / frame.width * CGFloat(manager.frameDomain.1 - manager.frameDomain.0))
        }
        intercept -= Double(event.deltaY)
    }
    
    func rightMouseDown(frame: NSRect, location: CGPoint) {}
    
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
        if amplitude == 0 {
            amplitude += 0.1
        } else {
            amplitude *= (1 + Double(event.deltaY / frame.height))
        }
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
