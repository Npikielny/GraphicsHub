//
//  Animator.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/1/21.
//

import Cocoa

var inputIndex: Int = 0
protocol InputAnimator {
    static var name: String { get }
    var id: Int { get }
    var displayDomain: (Int, Int)? { get }
    var displayRange: (Double, Double)? { get }
    var input: AnimateableInterface { get }
    var manager: AnimatorManager { get }
    init(input: AnimateableInterface, manager: AnimatorManager, index: Int)
    
    func getFrame(_ frame: Int) -> Double
    func drawPath(_ frame: NSRect) -> NSBezierPath
    func drawPoints(_ frame: NSRect) -> [NSBezierPath]
    func getDescription() -> NSString?
    func leftMouseDown(location: CGPoint)
    func leftMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect)
    func rightMouseDown(location: CGPoint)
    func rightMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect)
    func scrollWheel(with event: NSEvent)
}

extension InputAnimator {
    func getDomain() -> (Int?, Int?) {
        let data = input.keyFrames.reduce([], +).map({$0.0})
        return (data.min(), data.max())
    }

    func getRange() -> (Double?, Double?) {
        if input.keyFrames.count == 0 {
            return (0, 1)
        }
        let compactedData = input.keyFrames.reduce([], +).map({ $1 })
        let min = compactedData.min()
        let max = compactedData.max()
        return (min, max)
    }
    
    func getPosition(frame: NSRect, frameRange: (Int, Int), position: (Int, Double)) -> NSPoint {
        let dx = frameRange.1 - frameRange.0
        if let displayRange = displayRange {
            let height = 1.5 * (position.1 - (displayRange.1 + displayRange.0) / 2) / (displayRange.1 - displayRange.0)
            return NSPoint(x: frame.width * CGFloat(position.0) / CGFloat(dx), y: CGFloat(height) * frame.height / 2 + frame.height / 2)
        }
        return NSPoint(x: frame.width * CGFloat(position.0) / CGFloat(dx), y: CGFloat(position.1) + frame.height / 2)
    }
    
    func findPosition(frame: NSRect, frameRange: (Int, Int), position: NSPoint) -> (Int, Double) {
        let frameIndex = Int((position.x / frame.width) * CGFloat(frameRange.1 - frameRange.0) + CGFloat(frameRange.0))
        if let displayRange = displayRange {
            return (frameIndex, ((Double(position.y / frame.height * 2 - frame.height / 2)) * (displayRange.1 - displayRange.0) + (displayRange.1 + displayRange.0) / 2)/1.5)
        }
        return (frameIndex, Double(position.y - frame.height / 2))
    }
    
    func draw(frameRange: (Int, Int), frame: NSRect, points: Int...) -> NSBezierPath {
        draw(frameRange: frameRange, frame: frame, points: points)
    }
    
    func draw(frameRange: (Int, Int), frame: NSRect, points: [Int]) -> NSBezierPath {
        let path = NSBezierPath()
        path.lineWidth = 3
        if frameRange.1 - frameRange.0 == 0 {
            let height = getFrame(frameRange.0)
            path.move(to: NSPoint(x: 0, y: CGFloat(height) + frame.height / 2))
            path.line(to: NSPoint(x: frame.width, y: CGFloat(height) + frame.height / 2))
            return path
        }
        path.move(to: getPosition(frame: frame, frameRange: frameRange, position: (frameRange.0, getFrame(frameRange.0))))
        for i in frameRange.0...frameRange.1 {
            path.line(to: getPosition(frame: frame, frameRange: frameRange, position: (i, getFrame(i))))
        }
        return path
    }
    
    func drawPoints(frameRange: (Int, Int), frame: NSRect, points: Int...) -> [NSBezierPath] {
        return drawPoints(frameRange: frameRange, frame: frame, pointsList: points)
    }
    
    func drawPoints(frameRange: (Int, Int), frame: NSRect, pointsList: [Int]) -> [NSBezierPath] {
        var paths = [NSBezierPath]()
        for point in pointsList {
            if frameRange.1 - frameRange.0 == 0 {
                if point == frameRange.0 {
                    let pointPosition = NSPoint(x: frame.width / 2, y: CGFloat(getFrame(point)) + frame.height / 2)
                    let path = NSBezierPath(roundedRect: NSRect(x: pointPosition.x - 5,
                                                                     y: pointPosition.y - 5,
                                                                     width: 10,
                                                                     height: 10),
                                                 xRadius: 5,
                                                 yRadius: 5)
                    path.lineWidth = 3
                    paths.append(path)
                }
            } else {
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
            
        }
        return paths
    }
}

class LinearAnimator: InputAnimator {
    
    static var name: String = "Linear Animator"
    var id: Int
    
    var displayDomain: (Int, Int)?
    
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
        if input.keyFrames.count == 0 {
            let current = input.doubleOutput[index]
            if current == 0 {
                displayRange = (-5, 5)
            } else {
                displayRange = (current * 0.5, current * 1.5)
            }
        }
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
        let beforeValue = beforeUnwrapped.1
        guard let afterUnwrapped = before else { return beforeValue }
        let afterValue = afterUnwrapped.1
        
        let p = (Double(frame) - Double(beforeUnwrapped.0))/(Double(afterUnwrapped.0) - Double(beforeUnwrapped.0))
        return (afterValue - beforeValue) * p + beforeValue
    }
    
    func drawPath(_ frame: NSRect) -> NSBezierPath {
        return draw(frameRange: displayDomain ?? manager.frameRange, frame: frame, points: input.keyFrames[index].map({$0.0}))
    }
    
    func drawPoints(_ frame: NSRect) -> [NSBezierPath] {
        []
    }
    
    func leftMouseDown(location: CGPoint) {
        let frame: Int = 0
        let data: Double = 1
        input.addKeyFrame(index: index, frame: frame, value: data)
    }
    
    func leftMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect) {
        
    }
    
    func rightMouseDown(location: CGPoint) {}
    
    func rightMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect) {}
    
    func scrollWheel(with event: NSEvent) {}
    
    func getDescription() -> NSString? {
        nil
    }
}

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
    
    func leftMouseDown(location: CGPoint) { }
    
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
            period -= 0.1
        } else if delta > 0 {
            period += 0.1
        }
        if period < 0 {
            period = 0
        }
    }
    
}
