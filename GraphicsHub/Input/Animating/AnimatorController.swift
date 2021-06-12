//
//  AnimatorController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/24/21.
//

import Cocoa
import SceneKit

class AnimatorController: NSViewController {

    override var acceptsFirstResponder: Bool { true }
    
    let animatorManager: AnimatorManager
    
    var selectorButton: NSPopUpButton!

    private let graphView: GraphView = {
        let view = GraphView()
        view.wantsLayer = true
        return view
    }()
    
    private let framesLabel: NSText = {
        let text = NSText()
        text.string = "Frame Range: "
        text.font = .systemFont(ofSize: 15)
        text.isEditable = false
        text.isSelectable = false
        text.backgroundColor = .clear
        return text
    }()
    
    private lazy var minFrame: NSTextField = {
        let field = NSTextField()
        field.stringValue = "0"
        field.delegate = self
        field.bezelStyle = .roundedBezel
        field.isBezeled = true
        return field
    }()
    
    private lazy var maxFrame: NSTextField = {
        let field = NSTextField()
        field.stringValue = "0"
        field.delegate = self
        field.bezelStyle = .roundedBezel
        field.isBezeled = true
        return field
    }()
    
    var checkTimer: Timer?
    
    init(inputManager: RendererInputManager) {
        self.animatorManager = AnimatorManager(manager: inputManager)
        super.init(nibName: "AnimatorController", bundle: nil)
        selectorButton = NSPopUpButton(title: "", target: self, action: #selector(setInput))
        selectorButton.addItems(withTitles: animatorManager.animations.map({
            ($0.key as! AnimateableInterface).name
        }))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        [selectorButton, graphView, framesLabel, minFrame, maxFrame].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0!)
        }
        
        view.addConstraintsWithFormat(format: "|-15-[v0(150)]", views: selectorButton)
        view.addConstraintsWithFormat(format: "[v0(110)]-5-[v1(50)]-5-[v2(50)]-15-|", views: framesLabel, minFrame, maxFrame)
        framesLabel.leadingAnchor.constraint(greaterThanOrEqualTo: selectorButton.trailingAnchor, constant: 5).isActive = true
        
        [selectorButton, framesLabel, minFrame, maxFrame].forEach {
            $0?.topAnchor.constraint(equalTo: view.topAnchor, constant: 15).isActive = true
            $0?.heightAnchor.constraint(equalToConstant: 20).isActive = true
        }
        
        NSLayoutConstraint.activate([
            graphView.topAnchor.constraint(equalTo: selectorButton.bottomAnchor, constant: 5),
            graphView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            graphView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            graphView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15),
            
            
        ])
        graphView.layer?.backgroundColor = NSColor.black.cgColor
        setAnimators()
        setFrameRange()
    }
    
    @objc func setInput(_ sender: NSButton) {
        setAnimators()
    }
    
    private func setAnimators() {
        guard let animators = animatorManager.animations.first(where: { ($0.key as? AnimateableInterface)?.name == selectorButton.selectedItem?.title })?.value else { print("FOund nothin"); return }
        graphView.animators = animators
        graphView.display()
    }
    func checkFrameRange() {
        checkTimer?.invalidate()
        let isValid: (NSTextField) -> Bool = { return (Int($0.stringValue)) != nil}
        if !isValid(minFrame) && !isValid(maxFrame) {
            minFrame.stringValue = "0"
            maxFrame.stringValue = "0"
        } else if !isValid(minFrame) {
            minFrame.stringValue = maxFrame.stringValue
        } else  if !isValid(maxFrame) {
            maxFrame.stringValue = minFrame.stringValue
        }
        if Int(maxFrame.stringValue)! < Int(minFrame.stringValue)! {
            maxFrame.stringValue = minFrame.stringValue
        }
        setFrameRange()
    }
    
    func setFrameRange() {
        if let frameRange = (Int(minFrame.stringValue), Int(maxFrame.stringValue)) as? (Int, Int) {
            animatorManager.frameRange = frameRange
            graphView.display()
        }
    }
    
    func drawGraphs(animators: [InputAnimator]) {
        graphView.animators = animators
        graphView.draw(graphView.frame)
    }
    
}

extension AnimatorController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
            self.checkFrameRange()
        })
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        checkFrameRange()
    }
    
}
