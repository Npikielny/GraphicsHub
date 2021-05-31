//
//  Input.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import Cocoa

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

class Input<T>: NSView, InputShell {
    
    var name: String
    
    private var current: T {
        didSet {
            changed = true
        }
    }
    private var changed = false
    var didChange: Bool { changed }
    internal var defaultValue: T
    
    var transform: ((T) -> T)?
    var output: T { changed = false; return current }
    
    internal var showingConstraints = [NSLayoutConstraint]()
    internal var hidingConstraints = [NSLayoutConstraint]()
    
    private var showingMainConstraint: NSLayoutConstraint!
    internal var expectedHeight: CGFloat {
        didSet {
            
        }
    }
    
    init(name: String, defaultValue: T, transform: ((T) -> T)? = nil, expectedHeight: CGFloat) {
        self.transform = transform
        self.name = name
        self.current = defaultValue
        self.defaultValue = defaultValue
        self.expectedHeight = expectedHeight
        
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        showingMainConstraint = heightAnchor.constraint(equalToConstant: expectedHeight)
        
        hidingConstraints.append(contentsOf: [])
        expand()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reset() {
        self.current = defaultValue
    }
    
    func collapse() {
        NSLayoutConstraint.deactivate(showingConstraints)
        NSLayoutConstraint.activate(hidingConstraints)
        showingMainConstraint.constant = 0
        
    }
    func expand() {
        NSLayoutConstraint.deactivate(hidingConstraints)
        NSLayoutConstraint.activate(showingConstraints)
        showingMainConstraint.constant = expectedHeight
    }
    
}

protocol AnimateableShell {}

class Animateable<T>: Input<T>, AnimateableShell {
    func lerpSet(a: T, b: T, p: Double) {}
    var keyFrames = [Int: T]()
    
    func addKeyFame(index: Int) {
        keyFrames[index] = super.output
    }
    func addAnimationButtons(rightAnchor: NSLayoutXAxisAnchor) {
        
    }
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
    convenience init(vector: SIMD3<Float>) {
        self.init(red: CGFloat(vector.x),
                  green: CGFloat(vector.y),
                  blue: CGFloat(vector.z),
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
