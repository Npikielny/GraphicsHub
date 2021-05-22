//
//  Input.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import Cocoa

enum AnimationType {
    case sinusoidal
    case linear
}
protocol Containable {
    init(name: String)
}
protocol InputShell {
    func reset()
    func collapse()
    func expand()
    var didChange: Bool { get }
    var name: String { get set}
}

protocol Input: InputShell {
    associatedtype OutputType
    var output: OutputType { get }
    var transform: ((OutputType) -> OutputType)? { get }
}
protocol Animateable {
    associatedtype OutputType
    func lerpSet(a: OutputType, b: OutputType, p: Double)
}
// TODO: Text Input

// Switch
// TODO: Switch

// TODO: Increment

extension NSColor {
    convenience init(color: SIMD4<Float>) {
        self.init(red: CGFloat(color.x),
                  green: CGFloat(color.y),
                  blue: CGFloat(color.z),
                  alpha: CGFloat(color.w))
    }
    convenience init(color: SIMD3<Float>) {
        self.init(red: CGFloat(color.x),
                  green: CGFloat(color.y),
                  blue: CGFloat(color.z),
                  alpha: 1)
    }
    func toVector() -> SIMD4<Float> {
        return SIMD4<Float>(Float(redComponent),
                            Float(greenComponent),
                            Float(blueComponent),
                            Float(alphaComponent))
    }
    func toVector() -> SIMD3<Float> {
        return SIMD3<Float>(Float(redComponent),
                            Float(greenComponent),
                            Float(blueComponent))
    }
    
}

extension CGColor {
    func toVector() -> SIMD3<Float> {
        if numberOfComponents >= 3 {
            guard let components = components else {
                return SIMD3<Float>(1,1,1)
            }
            return SIMD3<Float>(Float(components[0]),Float(components[1]),Float(components[2]))
        }
        return SIMD3<Float>(1,1,1)
    }
}

extension CGPoint {
    func toVector() -> SIMD2<Float> {
        return SIMD2<Float>(Float(x),Float(y))
    }
    func toInverseVector() -> SIMD2<Float> {
        return SIMD2<Float>(Float(y),Float(x))
    }
}
