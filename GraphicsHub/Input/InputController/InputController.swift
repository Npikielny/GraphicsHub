//
//  InputController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import Cocoa

class InputController: NSViewController {

    var inputs: [NSView]
    var animator: AnimatorController?
    private var animatorWindow: NSWindow?
    let padding: CGFloat = 20
    
    init(inputManager: InputManager) {
        self.inputs = inputManager.inputs
        if let inputManager = inputManager as? RendererInputManager {
            self.animator = AnimatorController(inputManager: inputManager)
            animatorWindow = NSWindow(contentViewController: animator!)
            animatorWindow?.title = "Animator"
        }
        super.init(nibName: "InputController", bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.wantsLayer = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    fileprivate func setupScrollView() {
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
        ])
        scrollView.layer?.backgroundColor = NSColor.clear.cgColor
        scrollView.backgroundColor = .clear
        scrollView.documentView?.layer?.backgroundColor = NSColor.clear.cgColor
        var last: NSLayoutYAxisAnchor = scrollView.contentView.topAnchor
        for input in inputs {
            scrollView.contentView.addSubview(input)
            NSLayoutConstraint.activate([
                input.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor, constant: 10),
                input.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor, constant: -10),
                input.topAnchor.constraint(equalTo: last, constant: 10),
            ])
            last = input.bottomAnchor
        }
        last.constraint(lessThanOrEqualTo: scrollView.bottomAnchor).isActive = true
    }
    
    @objc func showAnimator() {
        animatorWindow?.makeKeyAndOrderFront(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = NSColor.clear.cgColor
        setupScrollView()
        if inputs.contains(where: { $0 is AnimateableInterface }) {
            let animatorButton = NSButton(title: "Animate", target: self, action: #selector(showAnimator))
            animatorButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(animatorButton)
            NSLayoutConstraint.activate([
                animatorButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
                animatorButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5),
                animatorButton.topAnchor.constraint(greaterThanOrEqualTo: scrollView.bottomAnchor),
            ])

        }
    }
    
}
