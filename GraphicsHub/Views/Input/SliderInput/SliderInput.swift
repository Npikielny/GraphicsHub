//
//  SliderInput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/19/21.
//

import Cocoa

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
