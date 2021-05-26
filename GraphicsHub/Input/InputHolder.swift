//
//  InputHolder.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/23/21.
//

import Cocoa

class InputHolder: NSView {

    var input: NSView
    var animateable: Bool
    
    init(input: NSView) {
        self.input = input
        if let _ = input as? Animateable {
            self.animateable = true
        } else {
            self.animateable = false
        }
        super.init(frame: .zero)
    }
    
    lazy var addKeyFrameButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.touchBarTextCenterAlignTemplateName)!, target: self, action: #selector(addKeyFrame))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    @objc func addKeyFrame() {
        
    }
    
    lazy var resetButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.refreshTemplateName)!, target: self, action: #selector(reset))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    @objc func reset() {
        if let input = input as? InputShell {
            input.reset()
        }
    }
    
    func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(input)
        input.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
//            input.topAnchor.constraint(equalTo: topAnchor),
//            input.leadingAnchor.constraint(equalTo: leadingAnchor),
//            input.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
//        if animateable {
//            [resetButton, addKeyFrameButton].forEach {
//                addSubview($0)
//                $0.topAnchor.constraint(equalTo: input.topAnchor).isActive = true
//            }
//            resetButton.leftAnchor.constraint(equalTo: input.rightAnchor, constant: 5).isActive = true
//            addKeyFrameButton.leftAnchor.constraint(equalTo: resetButton.rightAnchor, constant: 5).isActive = true
//            addKeyFrameButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
//        } else {
            addSubview(resetButton)
//            resetButton.topAnchor.constraint(equalTo: input.topAnchor).isActive = true
//            resetButton.leftAnchor.constraint(equalTo: input.leftAnchor).isActive = true
//            resetButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
//        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
