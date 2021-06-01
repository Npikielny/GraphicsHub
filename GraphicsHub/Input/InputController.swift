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
    
    var scrollView: NSScrollView = {
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
    
    var animator: NSWindow?
    @objc func showAnimator() {
        if let animator = animator {
            animator.makeKeyAndOrderFront(nil)
        } else {
            let animatableInputs: [AnimateableShell] = inputs.compactMap({ $0 as? AnimateableShell })
            animator = NSWindow(contentViewController: AnimatorController(inputs: animatableInputs))
            animator?.makeKeyAndOrderFront(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        if inputs.contains(where: { $0 is Animateable<Any> }) {
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
