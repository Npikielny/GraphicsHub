//
//  ColorInput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/19/21.
//

import Cocoa

class ColorPickerInput: Animateable<NSColor>, Containable {

    typealias OutputType = NSColor

    var defaultColor: NSColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
    
    override var output: NSColor {
        get {
            colorView.layer?.backgroundColor = colorPicker.color.cgColor
            return colorPicker.color
        }
        set {
            colorView.layer?.backgroundColor = newValue.cgColor
            colorPicker.color = newValue
        }
    }
    override var doubleOutput: [Double]! {
        let color = colorPicker.color
        return [
            Double(color.redComponent),
            Double(color.greenComponent),
            Double(color.blueComponent),
        ]
    }

    lazy var colorView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = defaultColor.cgColor
        view.layer?.cornerRadius = 10
        return view
    }()

    override func reset() {
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
    override func lerpSet(a: NSColor, b: NSColor, p: Double) {
        output = NSColor(red: (b.redComponent - a.redComponent) * CGFloat(p) + a.redComponent,
                         green: (b.greenComponent - a.greenComponent) * CGFloat(p) + a.greenComponent,
                         blue: (b.blueComponent - a.blueComponent) * CGFloat(p) + a.blueComponent,
                         alpha: (b.alphaComponent - a.alphaComponent) * CGFloat(p) + a.alphaComponent)
    }

    lazy var setColorButton: NSButton = NSButton(title: "Set Color", target: self, action: #selector(showPicker))

    private var heightAnchorConstraint: NSLayoutConstraint!
    
    lazy var colorPicker: NSColorPanel = {
        let cp = NSColorPanel()
        cp.color = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
        cp.isContinuous = true
        cp.mode = .wheel
        cp.showsAlpha = true
        cp.setAction(#selector(setColor))
        cp.setTarget(self)
        return cp
    }()

    init(name: String, defaultColor: NSColor, animateable: Bool) {
        super.init(name: name, defaultValue: defaultColor, transform: nil, expectedHeight: 30, requiredAnimators: 4, animateable: animateable, domain: [(0,1),(0,1),(0,1),(0,1)])
        titleLabel.string = name
        
        self.defaultColor = defaultColor
        
        reset()
        
        setupViews()
    }
    
    required init(name: String) {
        super.init(name: name,
                   defaultValue: NSColor(red: 1, green: 1, blue: 1, alpha: 1),
                   transform: nil,
                   expectedHeight: 30,
                   requiredAnimators: 3,
                   animateable: false,
                   domain: [(0,1),(0,1),(0,1),(0,1)])
        titleLabel.string = name

        reset()

        setupViews()
    }

    fileprivate func setupViews() {
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
        changed = true
    }
    
    @objc func showPicker() {
        colorPicker.makeKeyAndOrderFront(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
