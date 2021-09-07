//
//  TemplateController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import Cocoa

class TemplateController: NSViewController {

    private var color: NSColor
    init(color: NSColor) {
        self.color = color
        super.init(nibName: "TemplateController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = color.cgColor
    }
    
}
