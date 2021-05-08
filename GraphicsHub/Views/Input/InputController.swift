//
//  InputController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import Cocoa

class InputController: NSViewController {

    var inputs: [NSView]
    
    let padding: CGFloat = 20
    
    init(inputs: [NSView]) {
        self.inputs = inputs
        super.init(nibName: "InputController", bundle: nil)
        
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        var last = view.topAnchor
        inputs.forEach {
//            let resetButton = NSButton(title: "Reset", target: self, action: #selector($0))
            view.addSubview($0)
            $0.topAnchor.constraint(equalTo: last, constant: padding).isActive = true
            last = $0.bottomAnchor
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding).isActive = true
        }
        inputs.last?.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -padding).isActive = true
    }
    
}

class InputContainer: NSView {
    
    lazy var resetButton = NSButton(title: "Reset", target: self, action: #selector(reset))
    @objc func reset() {}
    lazy var addKeyFrameButton = NSButton(title: "+", target: self, action: #selector(addKeyFrame))
    @objc func addKeyFrame() {}
    
}
