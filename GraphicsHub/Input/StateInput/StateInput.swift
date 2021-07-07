//
//  StateInput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/19/21.
//

import Cocoa

class StateInput: Input<Bool>, Containable {
    
    typealias OutputType = Bool
    
    override var output: Bool {
        get { stateButton.state == .on }
        set {
            if newValue {
                stateButton.state = .on
            } else {
                stateButton.state = .off
            }
        }
    }
    
    override func reset() {
        output = false
    }
    
    private var stateButton: NSButton!
    @objc func stateChanged() {
        changed = true
    }
    
    convenience init(name: String, defaultValue: Bool = false) {
        self.init(name: name)
        self.defaultValue = defaultValue
        output = defaultValue
    }
    
    required init(name: String) {
        super.init(name: name, defaultValue: false, transform: nil, expectedHeight: 20)
        self.stateButton = NSButton(checkboxWithTitle: name, target: self, action: #selector(stateChanged))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var hidingConstraint: NSLayoutConstraint!
    
    private func setupView() {
        stateButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stateButton)
        stateButton.leadingAnchor.constraint(equalTo: documentView.leadingAnchor).isActive = true
        stateButton.trailingAnchor.constraint(equalTo: documentView.trailingAnchor).isActive = true
        stateButton.topAnchor.constraint(equalTo: documentView.topAnchor).isActive = true
        stateButton.bottomAnchor.constraint(equalTo: documentView.bottomAnchor).isActive = true
        hidingConstraint = stateButton.heightAnchor.constraint(equalToConstant: 0)
    }
}
