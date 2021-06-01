//
//  MainController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import Cocoa

class MainController: NSViewController {

    let renderingView: RenderingView
    init(size: CGSize) {
        renderingView = RenderingView(size: size)
        super.init(nibName: "MainController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        [renderingView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        renderingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        renderingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        renderingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        renderingView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
    }
    
}
