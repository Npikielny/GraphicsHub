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
    
    static let animationTypes: [InputAnimator.Type] = [
        LinearAnimator.self,
        SinusoidalAnimator.self
    ]
    
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
    
    var inputSpecificViews = [NSView]()
    var inputSpecificConstraints = [NSLayoutConstraint]()
    
    init(inputManager: RendererInputManager) {
        self.animatorManager = inputManager.animatorManager
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
            graphView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            graphView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            graphView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15),
        ])
        graphView.layer?.backgroundColor = NSColor.black.cgColor
        setFrameRange()
        setAnimators()
    }
    
    @objc func setInput(_ sender: NSButton) {
        setAnimators()
    }
    
    private func setAnimators() {
        graphView.editingIndex = 0
        guard let animators = animatorManager.animations.first(where: { ($0.key as? AnimateableInterface)?.name == selectorButton.selectedItem?.title })?.value else { return }
        graphView.animators = animators
        NSLayoutConstraint.deactivate(inputSpecificConstraints)
        inputSpecificConstraints = []
        inputSpecificViews.forEach {
            $0.removeFromSuperview()
        }
        inputSpecificViews = []

        var last = selectorButton.bottomAnchor
        for (index, animator) in animators.enumerated() {
            let selector = NSPopUpButton(title: "", target: self, action: #selector(setSpecificAnimator))
            for animator in AnimatorController.animationTypes {
                selector.addItem(withTitle: "\(animator.name)")
            }
            if let animatorIndex = AnimatorController.animationTypes.firstIndex(where: { $0 == type(of: animator)}) {
                selector.selectItem(at: animatorIndex)
            }
            inputSpecificViews.append(selector)
            
            inputSpecificConstraints.append(contentsOf: [
                selector.topAnchor.constraint(equalTo: last, constant: 5),
                selector.leadingAnchor.constraint(equalTo: selectorButton.leadingAnchor),
                selector.trailingAnchor.constraint(equalTo: selector.trailingAnchor),
                selector.heightAnchor.constraint(equalTo: selectorButton.heightAnchor)
            ])
            
            let editingButton = NSButton(radioButtonWithTitle: "", target: self, action: #selector(editInput(sender:)))
            inputSpecificViews.append(editingButton)
            if index == 0 {
                editingButton.state = .on
            }
            inputSpecificConstraints.append(contentsOf: [
                editingButton.leadingAnchor.constraint(equalTo: selector.trailingAnchor, constant: 5),
                editingButton.topAnchor.constraint(equalTo: last, constant: 5),
                editingButton.heightAnchor.constraint(equalTo: selectorButton.heightAnchor),
                editingButton.widthAnchor.constraint(equalTo: editingButton.heightAnchor)
            ])
            editingButton.bezelStyle = .circular
            
            last = selector.bottomAnchor
        }
        inputSpecificConstraints.append(graphView.topAnchor.constraint(equalTo: last, constant: 5))

        inputSpecificViews.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate(inputSpecificConstraints)
        graphView.display()
    }
    
    @objc func setSpecificAnimator(sender: Any) {
        guard let sender = sender as? NSPopUpButton else { return }
        guard let index = inputSpecificViews.firstIndex(of: sender) else { return }
        guard let interface = animatorManager.animations.first(where: { ($0.key as? AnimateableInterface)?.name == selectorButton.selectedItem?.title })?.key else { return }
        guard let animateableInterface = interface as? AnimateableInterface else { return }
        guard let animateableType = AnimatorController.animationTypes.first(where: { $0.name == sender.selectedItem?.title }) else { return }
        animatorManager.animations[interface]?[index / 2] = animateableType.init(input: animateableInterface, manager: animatorManager, index: index / 2)
        graphView.animators = animatorManager.animations[interface]
        graphView.display()
    }
    
    @objc func editInput(sender: Any) {
        guard let editingIndex = inputSpecificViews.firstIndex(of: sender as! NSButton) else { return }
        graphView.editingIndex = editingIndex / 2
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
