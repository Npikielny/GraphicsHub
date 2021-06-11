//
//  Animator.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/1/21.
//

import Cocoa

protocol InputAnimator {
    static var name: String { get }
    var displayDomain: (Int, Int)? { get }
    var displayRange: (Double, Double)? { get }
    var input: AnimateableInterface { get }
    var manager: AnimatorManager { get }
    init(input: AnimateableInterface, manager: AnimatorManager)
    
    func getFrame(_ frame: Int) -> Double
    func drawPath(_ frame: NSRect) -> NSBezierPath
    func drawPoints(_ frame: NSRect) -> [NSBezierPath]
    func pointPaths(_ frame: NSRect) -> [(NSBezierPath, Bool)]
    func mouseDown(location: CGPoint) -> Bool
    func mouseMoved(location: CGPoint)
}

extension InputAnimator {
    func getDomain() -> (Int?, Int?) {
        let data = input.data.map({$0.0})
        return (data.min(), data.max())
    }

    func getRange() -> (Double?, Double?) {
        if input.data.count == 0 {
            return (0, 1)
        }
        let min = input.data.map({$0.1.min()!}).min()
        let max = input.data.map({$0.1.max()!}).max()
        return (min, max)
    }
    
    func getPosition(frame: NSRect, frameRange: (Int, Int), position: (Int, Double)) -> NSPoint {
        let dx = frameRange.1 - frameRange.0
        return NSPoint(x: frame.width * CGFloat(position.0) / CGFloat(dx), y: CGFloat(position.1) + frame.height / 2)
    }
    
    func draw(frameRange: (Int, Int), frame: NSRect, points: Int...) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: getPosition(frame: frame, frameRange: frameRange, position: (frameRange.0, getFrame(frameRange.0))))
        for i in frameRange.0...frameRange.1 {
            path.line(to: getPosition(frame: frame, frameRange: frameRange, position: (i, getFrame(i))))
        }
        path.lineWidth = 3
        return path
    }
    
    func drawPoints(frameRange: (Int, Int), frame: NSRect, points: Int...) -> [NSBezierPath] {
        var paths = [NSBezierPath]()
        for point in points {
            let pointPosition = getPosition(frame: frame, frameRange: frameRange, position: (point, getFrame(point)))
            let path = NSBezierPath(roundedRect: NSRect(x: pointPosition.x - 5,
                                                             y: pointPosition.y - 5,
                                                             width: 10,
                                                             height: 10),
                                         xRadius: 5,
                                         yRadius: 5)
            path.lineWidth = 3
            paths.append(path)
            
        }
        return paths
    }
}

//class ConstantAnimator: InputAnimator {
//    
//    static var name: String = "Constant"
//    
//    var input: AnimateableInterface
//    
//    init(input: AnimateableInterface) {
//        self.input = input
//        let value = (input.doubleOutput ?? [0])[0]
//        displayRange = (value, value)
//    }
//    
//    var displayDomain: (Int, Int)? = nil
//    var displayRange: (Double, Double)
//    
//    func setFrame(frame: Int) {}
//    
//    func draw(in view: NSView) {}
//    
//    func mouseDown(location: CGPoint) -> Bool {
//        return false
//    }
//    
//    func mouseMoved(location: CGPoint) {}
//}

//class LinearAnimator: InputAnimator {
//    static var name: String = "Linear"
//
//    var displayDomain: (Int, Int)?
//    var displayRange: (Double, Double)!
//    var input: AnimateableInterface
//
//    init(input: AnimateableInterface) {
//        self.input = input
//        let domain = getDomain()
//        self.displayDomain = (
//            {
//                if let minRange = domain.0 {
//                    return minRange
//                }
//                return 0
//            }(),
//            {
//                if let maxRange = domain.1 {
//                    return maxRange
//                }
//                return 0
//            }()
//        )
//
//    }
//
//    func setFrame(frame: Int) {}
//
//    func draw(in view: NSView) {}
//
//    func mouseDown(location: CGPoint) -> Bool {}
//
//    func mouseMoved(location: CGPoint) {}
//}
class SinusoidalAnimator: InputAnimator {
    
    static var name: String = "Sinusoidal"
    
    var displayDomain: (Int, Int)? = nil
    var displayRange: (Double, Double)?
    
    var input: AnimateableInterface
    
    var locus: Double
    var period: Double
    var amplitude: Double
    
    var manager: AnimatorManager
    
    required init(input: AnimateableInterface, manager: AnimatorManager) {
        self.input = input
        let frameRange = manager.frameRange
        locus = Double(frameRange.0 + frameRange.1) / 2
        period = Double(frameRange.1 - frameRange.0)
        amplitude = 50
        self.manager = manager
    }
    
    func getFrame(_ frame: Int) -> Double {
        return amplitude * sin((Double(frame) - locus) / period * (2 * Double.pi))
    }
    
    func drawPath(_ frame: NSRect) -> NSBezierPath {
        return draw(frameRange: manager.frameRange, frame: frame, points: Int(locus))
    }
    
    func drawPoints(_ frame: NSRect) -> [NSBezierPath] {
        return drawPoints(frameRange: manager.frameRange, frame: frame, points: Int(locus))
    }
    
    func pointPaths(_ frame: NSRect) -> [(NSBezierPath, Bool)] {
        []
    }
    
    func mouseDown(location: CGPoint) -> Bool { return false }
    
    func mouseMoved(location: CGPoint) {}
}
