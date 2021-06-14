//
//  ListInput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/19/21.
//

import Cocoa

class ListInput<InputType, View: Input<InputType> & Containable >: Input<[InputType]> {

    var customizeable: Bool

    required convenience init(name: String) {
        self.init(name: name, inputs: [])
    }

    typealias OutputType = [InputType]

    override var didChange: Bool {
        get { inputs.contains { $0.didChange } }
        set {
            for i in 0..<inputs.count {
                inputs[i].didChange = newValue
            }
        }
    }
    var inputs = [View]()
    override var output: [InputType] { inputs.map { $0.output } }

    override func reset() {
        inputs.forEach { $0.reset() }
    }

    lazy var addButton = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(addInput))
    @objc func addInput() {
        if OutputType.self == [NSColor].self {
            addInputView(Views: [View.init(name: "Color \(inputs.count + 1)")], customizeable: customizeable)
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

    init(name: String, inputs: [View], customizeable: Bool = true) {
        self.customizeable = customizeable
        super.init(name: name, defaultValue: [], expectedHeight: inputs.map({$0.expectedHeight}).reduce(0, +) + 15)
        if customizeable {
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
        }
        addInputView(Views: inputs, customizeable: customizeable)
    }

    func addInputView(Views: [View], customizeable: Bool) {
        var last: NSLayoutYAxisAnchor!
        if inputs.count > 0 {
            last = (inputs.last! as! NSView).bottomAnchor
        } else {
            if customizeable {
                last = addButton.bottomAnchor
            } else {
                last = self.bottomAnchor
            }
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

    override func collapse() {
        inputs.forEach { $0.collapse() }
        super.collapse()
    }

    override func expand() {
        inputs.forEach { $0.expand() }
        super.expand()
    }

}
