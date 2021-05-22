//
//  ColorInput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/19/21.
//

import Cocoa

class ColorPickerInput: NSView, Input, Animateable, Containable {
    
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
            colorPicker.color = newValue
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
        colorView.layer?.backgroundColor = defaultColor.cgColor
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

        output = defaultColor
        colorView.layer?.backgroundColor = defaultColor.cgColor
        colorPicker.color = defaultColor
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


class ColorInput: NSView, Input {
    
    
    typealias OutputType = SIMD4<Float>
    
    var defaultColor:  SIMD4<Float>
    var last: SIMD4<Float>
    var output: SIMD4<Float> {
        didSet {
            colorView.layer?.backgroundColor = NSColor(color: defaultColor).cgColor
        }
    }
    
    var transform: ((SIMD4<Float>) -> SIMD4<Float>)?
    var didChange: Bool {
        let temp = last
        last = output
        return temp == output
    }
    
    var name: String
    
    var theta: Float = 0
    var r: Float = 0
    
    func reset() {
        
    }
    
    func collapse() {
        
    }
    
    func expand() {
        
    }
    
    var colorWheel: NSView = {
        let view = NSView()
        view.wantsLayer = true
        
        let layer = CAGradientLayer()
        layer.frame = CGRect(x: 64, y: 64, width: 160, height: 160)
        layer.colors = [NSColor.red.cgColor, NSColor.green.cgColor, NSColor.blue]
        layer.type = .radial
        view.layer?.addSublayer(layer)
        
        return view
    }()
    
    var colorView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        return view
    }()
    
    init(name: String, defaultColor: SIMD4<Float>) {
        self.name = name
        self.defaultColor = defaultColor
        self.last = defaultColor
        output = defaultColor
        super.init(frame: .zero)
        colorView.layer?.backgroundColor = NSColor.red.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        
        [colorWheel, colorView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
            $0.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            $0.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 1).isActive = true
        }
        colorWheel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        colorWheel.trailingAnchor.constraint(equalTo: centerXAnchor).isActive = true
        colorView.leadingAnchor.constraint(equalTo: centerXAnchor).isActive = true
        colorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        heightAnchor.constraint(lessThanOrEqualToConstant: 50).isActive = true
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
