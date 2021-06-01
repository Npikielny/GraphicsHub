//
//  SliderInput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/19/21.
//

import Cocoa

class SliderInput: Animateable<Double> {
    
    typealias OutputType = Double

    private var changed: Bool = true
    override var didChange: Bool { if changed { changed = false; return true } else { return false } }
    override var output: OutputType {
        if let transform = transform {
            return transform(slider.doubleValue)
        } else {
            return slider.doubleValue
        }
    }

    var percent: Double { (slider.doubleValue - minValue) / (maxValue - minValue) }

    override func reset() {
        setValue(value: defaultValue)
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

    required convenience init(name: String) {
        self.init(name: name, minValue: 0, currentValue: 5, maxValue: 10)
    }
    
    init(name: String, minValue: Double, currentValue: Double, maxValue: Double, tickMarks: Int? = nil, transform: ((OutputType) -> OutputType)? = nil) {
        super.init(name: name, defaultValue: currentValue, transform: transform, expectedHeight: 100)
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

    var minValue: Double { slider.minValue }
    var maxValue: Double { slider.maxValue }

    override func lerpSet(a: Double, b: Double, p: Double) {
        setValue(value: (b - a) * p + a)
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
