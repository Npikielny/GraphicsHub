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
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        var last: NSLayoutYAxisAnchor = scrollView.contentView.safeAreaLayoutGuide.topAnchor
        for input in inputs {
            scrollView.contentView.addSubview(input)
            NSLayoutConstraint.activate([
                input.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
                input.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
                input.topAnchor.constraint(equalTo: last, constant: 10),
            ])
            last = input.bottomAnchor
        }
        inputs.last?.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupCollectionView()
        setupScrollView()
        
        
////        holderView.translatesAutoresizingMaskIntoConstraints = false
////        holderView.wantsLayer = true
////        holderView.layer?.backgroundColor = NSColor.red.cgColor
////        var last = holderView.topAnchor
////        inputs.forEach {
//////            let resetButton = NSButton(title: "Reset", target: self, action: #selector($0))
////            holderView.addSubview($0)
////            $0.topAnchor.constraint(equalTo: last, constant: padding).isActive = true
////            last = $0.bottomAnchor
////            $0.leadingAnchor.constraint(equalTo: holderView.leadingAnchor, constant: padding).isActive = true
////            $0.trailingAnchor.constraint(equalTo: holderView.trailingAnchor, constant: -padding).isActive = true
////        }
////        inputs.last?.bottomAnchor.constraint(lessThanOrEqualTo: holderView.bottomAnchor, constant: -padding).isActive = true
////        let scrollView = NSScrollView()
////        scrollView.translatesAutoresizingMaskIntoConstraints = false
////        view.addSubview(scrollView)
////        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
////        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
////        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
////        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
////        scrollView.hasVerticalRuler = true
////        scrollView.borderType = .lineBorder
////        scrollView.autoresizingMask = [.height,  .width]
////
////        holderView.setFrameSize(NSSize(width: view.frame.width, height: holderView.frame.height))
////        scrollView.documentView = holderView
////        view.translatesAutoresizingMaskIntoConstraints = false
////        view.wantsLayer = true
////        view.layer?.backgroundColor = NSColor.red.cgColor
        
//        var last = view.topAnchor
//        inputs.forEach {
////            let resetButton = NSButton(title: "Reset", target: self, action: #selector($0))
//            view.addSubview($0)
//            $0.topAnchor.constraint(equalTo: last, constant: padding).isActive = true
//            last = $0.bottomAnchor
//            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding).isActive = true
//            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding).isActive = true
//        }
//        inputs.last?.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -padding).isActive = true
        
////        let scrollView = NSScrollView()
////        scrollView.translatesAutoresizingMaskIntoConstraints = false
////        view.addSubview(scrollView)
////        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
////        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
////        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
////        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
////        scrollView.hasVerticalRuler = true
////        scrollView.borderType = .lineBorder
////        scrollView.autoresizingMask = [.height,  .width]
//
////        holderView.setFrameSize(NSSize(width: view.frame.width, height: holderView.frame.height))
////        scrollView.documentView = holderView
    }
}
