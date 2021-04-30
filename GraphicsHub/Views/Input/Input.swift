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
}

// Sliders
class SliderInput: NSView, Input {
    typealias InputType = Double
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
    private var label: NSTextView = {
        let tv = NSTextView()
        tv.backgroundColor = .clear
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
        defaultValue = currentValue
        titleLabel.string = name
        super.init(frame: .zero)
        
        slider = NSSlider(value: currentValue, minValue: minValue, maxValue: maxValue, target: self, action: #selector(valueChanged))
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
            titleLabel.widthAnchor.constraint(equalToConstant: 100),
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
    }
    
    func collapse() {
        heightAnchorConstraint.constant = 0
    }
    
    func expand() {
        heightAnchorConstraint.constant = 30
    }
}

extension SliderInput: NSTextViewDelegate {
    func textDidEndEditing(_ notification: Notification) {
        if let value = Double(label.string) {
            if value > slider.minValue && value < slider.maxValue {
                slider.doubleValue = value
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
    
    typealias InputType = NSColor
    
    private var defaultColor: NSColor
    var output: NSColor = .white { didSet { colorView.layer?.backgroundColor = output.cgColor } }
    var transform: ((NSColor) -> NSColor)?
    
    var colorView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
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
    
    init(defaultColor: NSColor, name: String) {
        self.defaultColor = defaultColor
        titleLabel.string = name
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
            titleLabel.widthAnchor.constraint(equalToConstant: 100),

            setColorButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            setColorButton.trailingAnchor.constraint(equalTo: trailingAnchor),

            colorView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 5),
            colorView.trailingAnchor.constraint(equalTo: setColorButton.leadingAnchor, constant: -5),

            heightAnchorConstraint
        ])
    }
    
    @objc func setColor() {}
    
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
// TODO: Y / N BUTTON

// Lists
class ListInput<inputType: Input>: NSView, Input {
    
    typealias InputType = [inputType.InputType]
    var inputs = [inputType]()
    var output: [inputType.InputType] { inputs.map { $0.output } }
    
    var transform: (([inputType.InputType]) -> [inputType.InputType])?
    
    func reset() {
        
    }
    
    lazy var addButton = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(addInput))
    @objc func addInput() {
        
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
    
    init(inputs: [inputType]) {
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
        addInputView(Views: inputs.reversed())
    }
    
    func addInputView(Views: [inputType]) {
        var last: NSLayoutYAxisAnchor?
        if inputs.count > 0 {
            last = (inputs.last! as! NSView).topAnchor
        }
        for View in Views {
            let view = View as! NSView
            addSubview(view)
            view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            if let last = last  {
                view.topAnchor.constraint(equalTo: last, constant: 5).isActive = true
            } else {
                view.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
            }
            last = view.bottomAnchor
            inputs.append(View)
        }
        (Views.last! as! NSView).bottomAnchor.constraint(lessThanOrEqualTo: addButton.topAnchor, constant: -5).isActive = true
        
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
