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
    var integralRenderingSetting: Bool { get }
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
    var integralRenderingSetting: Bool
    internal var changed = true
    var didChange: Bool {
        get { let temp = changed; changed = false; return temp }
        set { changed = newValue }
    }
    internal var defaultValue: T
    
    var transform: ((T) -> T)?
    var output: T { changed = false; return current }
    
    internal var showingConstraints = [NSLayoutConstraint]()
    internal var hidingConstraints = [NSLayoutConstraint]()
    
    private var showingMainConstraint: NSLayoutConstraint!
    internal var expectedHeight: CGFloat
    
    var animateable = false
    var documentView: NSView!
    
    init(name: String, defaultValue: T, transform: ((T) -> T)? = nil, expectedHeight: CGFloat, integralRenderingSetting: Bool = true) {
        self.transform = transform
        self.name = name
        self.current = defaultValue
        self.defaultValue = defaultValue
        self.expectedHeight = expectedHeight
        self.integralRenderingSetting = integralRenderingSetting
        super.init(frame: .zero)
        documentView = self
        
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
    var keyFrames: [[(Int, Double)]] { get }
    var doubleOutput: [Double]! { get }
    var domain: [(Double, Double)] { get }
    
    var didChange: Bool { get set }
    func set(_ value: [Double], frame: Int)
    func setDidChange(_ value: Bool)
    func addKeyFrame(index: Int, frame: Int, value: Double)
    func removeKeyFrame(index: Int, frame: Int)
}

extension AnimateableInterface {
    func addCurrentKeyFrame(currentFrame: Int) {
        for (index, output) in doubleOutput.enumerated() {
            addKeyFrame(index: index, frame: currentFrame, value: output)
        }
    }
}

class Animateable<T>: Input<T>, AnimateableInterface {
    
    var domain: [(Double, Double)]
    var doubleOutput: [Double]! { nil }
    
    private var _keyFrames = [[(Int, Double)]]()
    var keyFrames: [[(Int, Double)]] {
        get { _keyFrames }
        set { _keyFrames = newValue }
    }
    var requiredAnimators: Int
    
    lazy var keyFrameButton: KeyFrameButton = KeyFrameButton(target: self, action: #selector(addCurrentKeyFrame))
    
    var currentFrame: Int?
    
    init(name: String, defaultValue: T, transform: ((T) -> T)? = nil, expectedHeight: CGFloat, requiredAnimators: Int, animateable: Bool, integralRenderingSetting: Bool = true, domain: [(Double, Double)]) {
        self.domain = domain
        self.requiredAnimators = requiredAnimators
        super.init(name: name, defaultValue: defaultValue, transform: transform, expectedHeight: expectedHeight)
        self.animateable = animateable
        for _ in 0..<requiredAnimators {
            keyFrames.append([])
        }
        if animateable {
            documentView = NSView()
            documentView.translatesAutoresizingMaskIntoConstraints = false
            keyFrameButton.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(documentView)
            self.addSubview(keyFrameButton)
            NSLayoutConstraint.activate([
                documentView.topAnchor.constraint(equalTo: topAnchor),
                documentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                documentView.bottomAnchor.constraint(equalTo: bottomAnchor),
                keyFrameButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                keyFrameButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
                keyFrameButton.widthAnchor.constraint(lessThanOrEqualToConstant: 50),
                documentView.trailingAnchor.constraint(equalTo: keyFrameButton.leadingAnchor, constant: -5)
            ])
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func addCurrentKeyFrame() {
        keyFrameButton.currentState.toggle()
        keyFrameButton.setImage()
        
        guard let currentFrame = currentFrame else { return }
        
        if keyFrameButton.currentState {
            // FIXME: Probably doesn't work for compound inputs (DimensionalInput)
            addCurrentKeyFrame(currentFrame: currentFrame)
        } else {
            for index in 0..<keyFrames.count {
                keyFrames[index].removeAll(where: { $0.0 == currentFrame })
            }
        }
        
        print("Adding current frame as key frame")
    }
    
    func set(_ value: [Double], frame: Int) {
        self.currentFrame = frame
        if keyFrames.contains(where: { $0.contains(where: { $0.0 == frame }) }) {
            keyFrameButton.currentState = true
        } else {
            keyFrameButton.currentState = false
        }
        keyFrameButton.setImage()
    }
    func setDidChange(_ value: Bool) {
        didChange = value
    }
    func lerpSet(a: T, b: T, p: Double) {}
    
    func addKeyFrame(index: Int, frame: Int, value: Double) {
        removeKeyFrame(index: index, frame: frame)
        keyFrames[index].append((frame, value))
        keyFrames[index].sort(by: { $0.0 < $1.0 })
    }
    
    func removeKeyFrame(index: Int, frame: Int) {
        keyFrames[index].removeAll(where: { $0.0 == frame})
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
// TODO: Compound animators
//
//class CompoundAnimateable<T>: Animateable<T> {
//    internal var innerInputs = [Animateable]()
//}

// TODO: Text Input

// Switch
// TODO: Switch

// TODO: Increment
