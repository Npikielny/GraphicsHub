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
    var displayRange: (Double, Double)? { get }
    var input: AnimateableInterface { get }
    var manager: AnimatorManager { get }
    var index: Int { get }
    init(input: AnimateableInterface, manager: AnimatorManager, index: Int)
    
    func getFrame(_ frame: Int) -> Double
    func drawPath(_ frame: NSRect) -> NSBezierPath
    func drawPoints(_ frame: NSRect) -> [NSBezierPath]
    func getDescription() -> NSString?
    func leftMouseDown(frame: NSRect, location: CGPoint)
    func leftMouseDragged(with event: NSEvent, location: CGPoint, frame: NSRect)
    func rightMouseDown(frame: NSRect, location: CGPoint)
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
        let displayRange = input.domain[index]
//        let height = (position.1 - (displayRange.1 + displayRange.0)) / (displayRange.1 - displayRange.0) // CGFloat(position.1 - displayRange.0) * frame.height / CGFloat(displayRange.1 - displayRange.0)
        let height = CGFloat(position.1 - displayRange.0) * frame.height / CGFloat(displayRange.1 - displayRange.0)
        return NSPoint(x: frame.width * CGFloat(position.0 - frameRange.0) / CGFloat(dx), y: height)
    }
    
    func findPosition(frame: NSRect, frameRange: (Int, Int), position: NSPoint) -> (Int, Double) {
        let frameIndex = Int((position.x / frame.width) * CGFloat(frameRange.1 - frameRange.0 + 1) + CGFloat(frameRange.0))
        let displayRange = input.domain[index]
        return (frameIndex, Double(position.y / frame.height) * (displayRange.1 - displayRange.0) + displayRange.0)
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
    
    func drawPoints(frameRange: (Int, Int), frame: NSRect, pointsList: [Int], are keyFrames: Bool = false) -> [NSBezierPath] {
        var paths = [NSBezierPath]()
        let valueHeight: (Int) -> Double = {
            if keyFrames {
                return { keyFrame in input.keyFrames[index].first(where: {$0.0 == keyFrame})!.1 }
            } else {
                return { keyFrame in getFrame(keyFrame) }
            }
        }()
        
        
        for point in pointsList {
            if frameRange.1 - frameRange.0 == 0 {
                let pointPosition = NSPoint(x: frame.width / 2, y: CGFloat(valueHeight(point)) + frame.height / 2)
                let path = NSBezierPath(roundedRect: NSRect(x: pointPosition.x - 5,
                                                            y: pointPosition.y - 5,
                                                            width: 10,
                                                            height: 10),
                                        xRadius: 5,
                                        yRadius: 5)
                path.lineWidth = 3
                paths.append(path)
            } else {
                let pointPosition = getPosition(frame: frame, frameRange: frameRange, position: (point, valueHeight(point)))
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
    
    func drawCurrentPoint(frame: NSRect, frameIndex: Int) -> NSBezierPath {
        return drawPoints(frameRange: manager.frameDomain, frame: frame, pointsList: [frameIndex])[0]
    }
}
