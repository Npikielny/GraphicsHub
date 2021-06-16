//
//  SliderInput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/19/21.
//

import Cocoa

class SliderInput: Animateable<Double> {
    
    typealias OutputType = Double
    
    override var output: OutputType {
        if let transform = transform {
            return transform(slider.doubleValue)
        } else {
            return slider.doubleValue
        }
    }
    override var doubleOutput: [Double]! {
        [output]
    }

    var percent: Double { (slider.doubleValue - minValue) / (maxValue - minValue) }

    private var slider: NSSlider!
    private lazy var label: NSTextField = {
        let tv = NSTextField()
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

    required convenience init(name: String) {
        self.init(name: name, minValue: 0, currentValue: 5, maxValue: 10)
    }
    
    init(name: String, minValue: Double, currentValue: Double, maxValue: Double, tickMarks: Int? = nil, transform: ((OutputType) -> OutputType)? = nil, animateable: Bool = true) {
        super.init(name: name, defaultValue: currentValue, transform: transform, expectedHeight: 100, requiredAnimators: 1, animateable: animateable, domain: [(minValue, maxValue)])
        titleLabel.string = name
        slider = NSSlider(value: currentValue, minValue: minValue, maxValue: maxValue, target: self, action: #selector(valueChanged))
        slider.isContinuous = true
        if let tickMarks = tickMarks {
            slider.numberOfTickMarks = tickMarks
            slider.allowsTickMarkValuesOnly = true
        }
        assignLabel()

        ([titleLabel, slider, label] as [NSView]).forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: 150),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            slider.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 5),
            slider.rightAnchor.constraint(equalTo: label.leftAnchor, constant: -5),

            label.topAnchor.constraint(equalTo: topAnchor),
            label.widthAnchor.constraint(equalToConstant: 50),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reset() {
        setValue(value: defaultValue)
    }

    private func assignLabel() {
        label.stringValue = String(floor(output * 100)/100)
    }

    @objc func valueChanged() {
        assignLabel()
        changed = true
    }

    override func set(_ value: [Double]) {
        setValue(value: value[0])
    }
    
    func setValue(value: Double) {
        if slider.doubleValue != value {
            slider.doubleValue = value
            assignLabel()
            changed = true
        }
    }
    
    func resizeableSet(value: Double) {
        if slider.doubleValue != value {
            slider.minValue = slider.minValue > value ? value : slider.minValue
            slider.maxValue = slider.maxValue < value ? value : slider.maxValue
            slider.doubleValue = value
            assignLabel()
            changed = true
        }
    }

    func setValue(percent: Double) {
        setValue(value: (slider.maxValue - slider.minValue) * percent + slider.minValue)
    }

    var minValue: Double { slider.minValue }
    var maxValue: Double { slider.maxValue }

    override func lerpSet(a: Double, b: Double, p: Double) {
        setValue(value: (b - a) * p + a)
    }
}

extension SliderInput: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        if label.stringValue == "" { return }
        if let value = Double(label.stringValue) {
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
