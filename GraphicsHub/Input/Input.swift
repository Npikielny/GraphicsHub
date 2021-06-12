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
    
    var animateable = false
    
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

protocol AnimateableInterface {
    var name: String { get }
    var animateable: Bool { get }
    var requiredAnimators: Int { get }
    var data: [(Int, [Double])] { get }
    var doubleOutput: [Double]? { get }
    
    func set(_ value: [Double])
}

class Animateable<T>: Input<T>, AnimateableInterface {
    
    var requiredAnimators: Int
    var keyFrames = [(Int, T)]()
    
    var doubleOutput: [Double]? { convert(from: super.output) }
    var data: [(Int, [Double])] {
        keyFrames.compactMap {
            if let value = convert(from: $0.1) {
                return ($0.0, value)
            }
            return nil
        }
    }
    
    init(name: String, defaultValue: T, transform: ((T) -> T)? = nil, expectedHeight: CGFloat, requiredAnimators: Int) {
        self.requiredAnimators = requiredAnimators
        super.init(name: name, defaultValue: defaultValue, transform: transform, expectedHeight: expectedHeight)
        animateable = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(_ value: [Double]) {}
    func lerpSet(a: T, b: T, p: Double) {}
    
    func addKeyFame(index: Int) {
        keyFrames.removeAll(where: { $0.0 == index })
        keyFrames.append((index, super.output))
    }
    func addAnimationButtons(rightAnchor: NSLayoutXAxisAnchor) {
        
    }
    
    func convert(to value: Double) -> T? {
        return nil
    }
    
    func convert(from value: T) -> [Double]? {
        return nil
    }
}

// TODO: Text Input

// Switch
// TODO: Switch

// TODO: Increment
