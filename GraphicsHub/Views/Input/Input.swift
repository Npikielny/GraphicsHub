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

protocol Input {
    associatedtype InputType
    var output: InputType { get }
    var transform: ((InputType) -> InputType)? { get }
    func reset()
    func collapse()
    func expand()
    var didChange: Bool { get }
    var name: String { get set}
    init(name: String)
    
}

// Sliders
class SliderInput: NSView, Input {
    var name: String
    
    required convenience init(name: String) {
        self.init(name: name, minValue: 0, currentValue: 5, maxValue: 10)
    }
    
    typealias InputType = Double
    
    private var changed: Bool = true
    var didChange: Bool { if changed { changed = false; return true } else { return false } }
    var output: InputType {
        if let transform = transform {
            return transform(slider.doubleValue)
        } else {
            return slider.doubleValue
        }
    }
    private var defaultValue: InputType
    var transform: ((Double) -> Double)?
    func reset() {
        slider.doubleValue = defaultValue
        assignLabel()
    }
    private var slider: NSSlider!
    private lazy var label: NSTextView = {
        let tv = NSTextView()
        tv.backgroundColor = .clear
        tv.delegate = self
//        tv.isEditable = false
//        tv.isSelectable = false
        return tv
    }()
    private var titleLabel: NSTextView = {
        let tv = NSTextView()
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 15)
        tv.isEditable = false
        tv.isSelectable = false
        return tv
    }()
    
    private var heightAnchorConstraint: NSLayoutConstraint!
    
    init(name: String, minValue: Double, currentValue: Double, maxValue: Double, tickMarks: Int? = nil, transform: ((InputType) -> InputType)? = nil) {
        self.name = name
        defaultValue = currentValue
        titleLabel.string = name
        super.init(frame: .zero)
        
        slider = NSSlider(value: currentValue, minValue: minValue, maxValue: maxValue, target: self, action: #selector(valueChanged))
        slider.isContinuous = true
        if let tickMarks = tickMarks {
            slider.numberOfTickMarks = tickMarks
            slider.allowsTickMarkValuesOnly = true
        }
        assignLabel()
        
        translatesAutoresizingMaskIntoConstraints = false
        ([titleLabel, slider, label] as [NSView]).forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        heightAnchorConstraint = heightAnchor.constraint(equalToConstant: 30)
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: 150),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            slider.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 5),
            slider.rightAnchor.constraint(equalTo: label.leftAnchor, constant: -5),

            label.topAnchor.constraint(equalTo: topAnchor),
            label.widthAnchor.constraint(equalToConstant: 50),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightAnchorConstraint
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func assignLabel() {
        label.string = String(floor(output * 100)/100)
    }
    @objc func valueChanged() {
        assignLabel()
        changed = true
    }
    
    func setValue(value: Double) {
        self.slider.doubleValue = value
        assignLabel()
        changed = true
    }
    
    func collapse() {
        heightAnchorConstraint.constant = 0
    }
    
    func expand() {
        heightAnchorConstraint.constant = 30
    }
}

extension SliderInput: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        if label.string == "" { return }
        if let value = Double(label.string) {
            if value > slider.minValue && value < slider.maxValue {
                slider.doubleValue = value
                changed = true
            } else {
                assignLabel()
            }
        } else {
            assignLabel()
        }
    }
}
// Text Input

// Color
class ColorInput: NSView, Input {
    var name: String
    
    typealias InputType = NSColor
    
    private var lastColor: NSColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
    private var changed: Bool { lastColor != output}
    var didChange: Bool { if changed { lastColor = output; return true } else { return false } }
    
    var defaultColor: NSColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
    
    var output: NSColor {
        get {
            colorView.layer?.backgroundColor = colorPicker.color.cgColor
            return colorPicker.color
        }
        set {
            colorView.layer?.backgroundColor = newValue.cgColor
        }
    }
    var transform: ((NSColor) -> NSColor)?
    
    lazy var colorView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = defaultColor.cgColor
        view.layer?.cornerRadius = 10
        return view
    }()
    
    func reset() {
        output = defaultColor
        colorView.layer?.backgroundColor = defaultColor.cgColor
    }
    
    var titleLabel: NSTextView = {
        let tv = NSTextView()
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 15)
        tv.isEditable = false
        tv.isSelectable = false
        return tv
    }()
    
    lazy var setColorButton: NSButton = NSButton(title: "Set Color", target: self, action: #selector(setColor))
    
    private var heightAnchorConstraint: NSLayoutConstraint!
    
    var colorPicker: NSColorPanel = {
        let cp = NSColorPanel()
        cp.color = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
        cp.isContinuous = true
        cp.mode = .wheel
        return cp
    }()
    
    convenience init(name: String, defaultColor: NSColor) {
        self.init(name: name)
        self.defaultColor = defaultColor
        _ = self.didChange
    }
    
    required init(name: String) {
        titleLabel.string = name
        self.name = name
        super.init(frame: .zero)
        
        reset()
        
        translatesAutoresizingMaskIntoConstraints = false
        [titleLabel, colorView].forEach { view in
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        heightAnchorConstraint = heightAnchor.constraint(equalToConstant: 30)
        addSubview(setColorButton)
        setColorButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 150),

            setColorButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            setColorButton.trailingAnchor.constraint(equalTo: trailingAnchor),

            colorView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 5),
            colorView.trailingAnchor.constraint(equalTo: setColorButton.leadingAnchor, constant: -5),

            heightAnchorConstraint
        ])
    }
    
    @objc func setColor() {
        colorPicker.makeKeyAndOrderFront(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collapse() {
        heightAnchorConstraint.constant = 0
    }
    
    func expand() {
        heightAnchorConstraint.constant = 30
    }
    
}

// TODO: 2D Inputs

// TODO: Y / N BUTTON
class StateInput: NSView, Input {
    
    typealias InputType = Bool
    
    private var changed = false
    var didChange: Bool {
        get {
            if changed {
                return true
            }
            changed = false
            return false
        }
    }
    
    var output: Bool {
        get { stateButton.state == .on }
        set {
            if newValue {
                stateButton.state = .off
            } else {
                stateButton.state = .on
            }
        }
    }
    
    var transform: ((Bool) -> Bool)?
    
    func reset() {
        output = false
    }
    
    func collapse() {
        hidingConstraint.isActive = true
    }
    
    func expand() {
        hidingConstraint.isActive = false
    }
    
    var name: String
    
    private var stateButton: NSButton!
    @objc func stateChanged() {
        changed = true
    }
    
    convenience init(name: String, defaultValue: Bool = false) {
        self.init(name: name)
        output = defaultValue
    }
    
    required init(name: String) {
        self.name = name
        super.init(frame: .zero)
        self.stateButton = NSButton(checkboxWithTitle: name, target: self, action: #selector(stateChanged))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var hidingConstraint: NSLayoutConstraint!
    
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        stateButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stateButton)
        stateButton.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stateButton.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stateButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stateButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        hidingConstraint = stateButton.heightAnchor.constraint(equalToConstant: 0)
    }
}
// Switch
// TODO: Switch
// TODO: Increment
// Lists
class ListInput<inputType: Input>: NSView, Input {
    var name: String
    
    required convenience init(name: String) {
        self.init(name: name, inputs: [])
    }
    
    typealias InputType = [inputType.InputType]
    
    var didChange: Bool { return inputs.contains { $0.didChange } }
    var inputs = [inputType]()
    var output: [inputType.InputType] { inputs.map { $0.output } }
    
    var transform: (([inputType.InputType]) -> [inputType.InputType])?
    
    func reset() {
        
    }
    
    lazy var addButton = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(addInput))
    @objc func addInput() {
        if InputType.self == [NSColor].self {
            addInputView(Views: [inputType.init(name: "Color \(inputs.count + 1)")])
        }
    }
    lazy var removeButton = NSButton(image: NSImage(named: NSImage.removeTemplateName)!, target: self, action: #selector(removeInput))
    @objc func removeInput() {
        
    }
    lazy var collapseButton = NSButton(image: NSImage(named: NSImage.touchBarGoUpTemplateName)!, target: self, action: #selector(collapseInputs))
    @objc func collapseInputs() {
        
    }
    lazy var expandButton = NSButton(image: NSImage(named: NSImage.touchBarGoDownTemplateName)!, target: self, action: #selector(expandInputs))
    @objc func expandInputs() {
        
    }
    
    init(name: String, inputs: [inputType]) {
        self.name = name
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        [addButton, removeButton, collapseButton, expandButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
            $0.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            removeButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor),
            collapseButton.leadingAnchor.constraint(equalTo: removeButton.trailingAnchor),
            expandButton.leadingAnchor.constraint(equalTo: collapseButton.trailingAnchor),
            expandButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            addButton.widthAnchor.constraint(equalTo: removeButton.widthAnchor, multiplier: 1),
            removeButton.widthAnchor.constraint(equalTo: collapseButton.widthAnchor, multiplier: 1),
            collapseButton.widthAnchor.constraint(equalTo: expandButton.widthAnchor, multiplier: 1),
        ])
        addInputView(Views: inputs)
    }
    
    func addInputView(Views: [inputType]) {
        var last: NSLayoutYAxisAnchor!
        if inputs.count > 0 {
            last = (inputs.last! as! NSView).topAnchor
        } else {
            last = addButton.topAnchor
        }
        for View in Views {
            let view = View as! NSView
            addSubview(view)
            view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            
            view.bottomAnchor.constraint(equalTo: last, constant: -5).isActive = true
            
            last = view.topAnchor
            inputs.append(View)
            view.layoutSubtreeIfNeeded()
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Add -> will need to add some window functions to protocol later
    // Remove?
    // Collapse
    // Show
    
    func collapse() {
        inputs.forEach { $0.collapse() }
    }
    
    func expand() {
        inputs.forEach { $0.expand() }
    }
    
}
