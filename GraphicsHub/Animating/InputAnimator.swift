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
    func leftMouseDown(frame: NSRect, location: CGPoint)
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
            let height = 1.5 * (position.1 - (displayRange.1 + displayRange.0) / 2) / (displayRange.1 - displayRange.0 + 1)
            return NSPoint(x: frame.width * CGFloat(position.0) / CGFloat(dx), y: CGFloat(height) * frame.height / 2 + frame.height / 2)
        }
        return NSPoint(x: frame.width * CGFloat(position.0) / CGFloat(dx), y: CGFloat(position.1) + frame.height / 2)
    }
    
    func findPosition(frame: NSRect, frameRange: (Int, Int), position: NSPoint) -> (Int, Double) {
        let frameIndex = Int((position.x / frame.width) * CGFloat(frameRange.1 - frameRange.0 + 1) + CGFloat(frameRange.0))
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