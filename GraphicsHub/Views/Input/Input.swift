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
// MARK: Sliders
class SliderInput: NSView, Animateable, Containable, Input {
    var name: String
    
    required convenience init(name: String) {
        self.init(name: name, minValue: 0, currentValue: 5, maxValue: 10)
    }
    
    typealias OutputType = Double
    
    private var changed: Bool = true
    var didChange: Bool { if changed { changed = false; return true } else { return false } }
    var output: OutputType {
        if let transform = transform {
            return transform(slider.doubleValue)
        } else {
            return slider.doubleValue
        }
    }
    var percent: Double { (slider.doubleValue - minValue) / (maxValue - minValue) }
    private var defaultValue: OutputType
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
    
    init(name: String, minValue: Double, currentValue: Double, maxValue: Double, tickMarks: Int? = nil, transform: ((OutputType) -> OutputType)? = nil) {
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
        if slider.doubleValue != value {
            slider.doubleValue = value
            assignLabel()
            changed = true
        }
    }
    func setValue(percent: Double) {
        setValue(value: (slider.maxValue - slider.minValue) * percent + slider.minValue)
    }
    func lerpSet(a: Double, b: Double, p: Double) {
        setValue(value: (b - a) * p + a)
    }
    
    func collapse() {
        heightAnchorConstraint.constant = 0
    }
    
    func expand() {
        heightAnchorConstraint.constant = 30
    }
    
    var minValue: Double { slider.minValue }
    var maxValue: Double { slider.maxValue }
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
// TODO: Text Input

// MARK: Color
class ColorInput: NSView, Input, Animateable, Containable {
    var name: String
    
    typealias OutputType = NSColor
    
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
    func lerpSet(a: NSColor, b: NSColor, p: Double) {
        output = NSColor(red: (b.redComponent - a.redComponent) * CGFloat(p) + a.redComponent,
                         green: (b.greenComponent - a.greenComponent) * CGFloat(p) + a.greenComponent,
                         blue: (b.blueComponent - a.blueComponent) * CGFloat(p) + a.blueComponent,
                         alpha: (b.alphaComponent - a.alphaComponent) * CGFloat(p) + a.alphaComponent)
    }
    
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

// MARK: Dimensional Inputs
internal class DimensionalInput<T>: NSView, Input {
    
    var output: T {
        get {
            dimensionalTransform(xSlider.output,ySlider.output)
        }
    }
    
    var transform: ((T) -> T)?
    var dimensionalTransform: (Double, Double) -> T
    
    var getDescription: (T) -> String
    
    var didChange: Bool {
        if xSlider.didChange || ySlider.didChange {
            draw()
            return true
        }
        return false
    }
    
    typealias OutputType = T
    
    func reset() {
        xSlider.reset()
        ySlider.reset()
    }
    
    func collapse() {
        xSlider.collapse()
        ySlider.collapse()
    }
    
    func expand() {
        xSlider.expand()
        ySlider.expand()
    }
    
    var name: String
    
    var xSlider: SliderInput
    var ySlider: SliderInput
    
    internal func setX(value: Double) {
        xSlider.setValue(value: value)
    }
    internal func setY(value: Double) {
        ySlider.setValue(value: value)
    }
    
    var displayView = NSView()
    
    init(name: String, xSlider: SliderInput, ySlider: SliderInput, dimensionalTransform: @escaping (Double, Double) -> T, transform: ((T) -> T)? = nil, getDescription: @escaping (T) -> String) {
        self.name = name
        self.xSlider = xSlider
        self.ySlider = ySlider
        self.dimensionalTransform = dimensionalTransform
        self.transform = transform
        self.getDescription = getDescription
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupViews()
        draw()
        
    }
    
    func setupViews() {
        displayView.wantsLayer = true
        displayView.layer?.borderWidth = 2
        displayView.layer?.borderColor = .black
        [xSlider, ySlider, displayView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
            if let _ = $0 as? SliderInput {
                $0.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
                $0.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
        }
        NSLayoutConstraint.activate([
            xSlider.topAnchor.constraint(equalTo: topAnchor),
            ySlider.topAnchor.constraint(equalTo: xSlider.bottomAnchor),
            displayView.topAnchor.constraint(equalTo: ySlider.bottomAnchor),
            displayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            displayView.widthAnchor.constraint(equalTo: displayView.heightAnchor, multiplier: CGFloat((xSlider.maxValue - xSlider.minValue)/(ySlider.maxValue - ySlider.minValue))),
            displayView.centerXAnchor.constraint(equalTo: centerXAnchor),
            displayView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            displayView.heightAnchor.constraint(lessThanOrEqualToConstant: 100),
            displayView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 1)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var acceptsFirstResponder: Bool { true }
    override func mouseDown(with event: NSEvent) {
        setSliders(event: event)
        draw()
    }
    override func mouseDragged(with event: NSEvent) {
        setSliders(event: event)
        draw()
    }
    func setSliders(event: NSEvent) {
        xSlider.setValue(percent: Double((event.locationInWindow.x - frame.minX - displayView.frame.minX)/(displayView.bounds.size.width)))
        ySlider.setValue(percent: Double((event.locationInWindow.y - frame.minY - displayView.frame.minY)/(displayView.bounds.size.height)))
    }
    var indicator = CAShapeLayer()
    private func draw() {
        let fillPath = CGMutablePath()
        let centerPoint = CGPoint(x: displayView.frame.width * CGFloat(xSlider.percent), y: displayView.frame.height * CGFloat(ySlider.percent))
        fillPath.addArc(center: centerPoint, radius: 5, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
        indicator.path = fillPath
        indicator.strokeColor = .black
        indicator.fillColor = .none
        displayView.layer?.addSublayer(indicator)
    }
}

class PointInput: DimensionalInput<CGPoint>, Animateable {
    override var output: CGPoint {
        get {
            dimensionalTransform(xSlider.output,ySlider.output)
        }
        set {
            xSlider.setValue(value: Double(newValue.x))
            ySlider.setValue(value: Double(newValue.y))
        }
    }
    var x: CGFloat { get { CGFloat(xSlider.output) } set { xSlider.setValue(value: Double(newValue)) } }
    var y: CGFloat { get { CGFloat(ySlider.output) } set { ySlider.setValue(value: Double(newValue)) } }
    
    func lerpSet(a: CGPoint, b: CGPoint, p: Double) {
        output = CGPoint(x: (b.x - a.x) * CGFloat(p) + a.x,
                       y: (b.x - a.x) * CGFloat(p) + a.y)
    }
    
    init(name: String, xName: String = "x", yName: String = "y", origin: CGPoint, size: CGSize) {
        super.init(name: name,
                   xSlider: SliderInput(name: xName, minValue: Double(origin.x - size.width/2), currentValue: Double(origin.x), maxValue: Double(origin.x + size.width/2)),
                   ySlider: SliderInput(name: yName, minValue: Double(origin.x - size.width/2), currentValue: Double(origin.x), maxValue: Double(origin.x + size.width/2)),
                   dimensionalTransform: { x, y in CGPoint(x: CGFloat(x), y: CGFloat(y))},
                   getDescription: { point in "(\(point.x), \(point.y)"})
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SizeInput: DimensionalInput<CGSize>, Animateable {
    override var output: CGSize {
        get {
            dimensionalTransform(xSlider.output,ySlider.output)
        }
        set {
            xSlider.setValue(value: Double(newValue.width))
            ySlider.setValue(value: Double(newValue.height))
        }
    }
    
    var width: CGFloat {
        get { CGFloat(xSlider.output) }
        set { xSlider.setValue(value: Double(newValue))}
    }
    var height: CGFloat {
        get { CGFloat(ySlider.output) }
        set { ySlider.setValue(value: Double(newValue))}
    }
    
    func lerpSet(a: CGSize, b: CGSize, p: Double) {
        output = CGSize(width: (b.width - a.width) * CGFloat(p) + a.width,
                        height: (b.height - a.height) * CGFloat(p) + a.height)
    }
    
    init(name: String, prefix: String?, minSize: CGSize = CGSize(width: 0, height: 0), size: CGSize, maxSize: CGSize) {
        super.init(name: name,
                   xSlider: SliderInput(name: (prefix ?? "") + " Width", minValue: Double(minSize.width), currentValue: Double(size.width), maxValue: Double(maxSize.width)),
                   ySlider: SliderInput(name: (prefix ?? "") + " Height", minValue: Double(minSize.height), currentValue: Double(size.height), maxValue: Double(maxSize.height)),
                   dimensionalTransform: { width, height in CGSize(width: CGFloat(width), height: CGFloat(height))},
                   getDescription: { size in "\(size.width) x \(size.height)"})
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// State Input
class StateInput: NSView, Input, Containable {
    
    typealias OutputType = Bool
    
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
class ListInput<inputType: Input & Containable>: NSView, Input {
    var name: String
    
    required convenience init(name: String) {
        self.init(name: name, inputs: [])
    }
    
    typealias OutputType = [inputType.OutputType]
    
    var didChange: Bool { return inputs.contains { $0.didChange } }
    var inputs = [inputType]()
    var output: [inputType.OutputType] { inputs.map { $0.output } }
    
    var transform: (([inputType.OutputType]) -> [inputType.OutputType])?
    
    func reset() {
        inputs.forEach { $0.reset() }
    }
    
    lazy var addButton = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(addInput))
    @objc func addInput() {
        if OutputType.self == [NSColor].self {
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
            $0.topAnchor.constraint(equalTo: topAnchor).isActive = true
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
            last = (inputs.last! as! NSView).bottomAnchor
        } else {
            last = addButton.bottomAnchor
        }
        for View in Views {
            let view = View as! NSView
            addSubview(view)
            view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            
            view.topAnchor.constraint(equalTo: last, constant: 5).isActive = true
            
            last = view.bottomAnchor
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
