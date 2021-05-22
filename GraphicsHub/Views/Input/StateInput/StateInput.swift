//
//  StateInput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/19/21.
//

import Cocoa

class StateInput: NSView, Input, Containable {
    
    typealias OutputType = Bool
    
    private var changed = false
    var didChange: Bool {
        get {
            if changed {
                changed = false
                return true
            }
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
