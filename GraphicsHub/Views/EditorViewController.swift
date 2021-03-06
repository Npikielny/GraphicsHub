//
//  EditorViewController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import Cocoa

class EditorViewController: NSSplitViewController {
    
    private var renderingController: MainController
    init(controller: MainController) {
        self.renderingController = controller
        super.init(nibName: "EditorViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        
        splitView.dividerStyle = .paneSplitter
        minimumThicknessForInlineSidebars = 180
        
        guard let renderer = renderingController.renderingView.renderer else {
            addSplitViewItem(NSSplitViewItem(contentListWithViewController: TemplateController(color: .systemPink)))
            return
        }
        let inputController = InputController(inputManager: renderer.inputManager)
        addSplitViewItem(NSSplitViewItem(contentListWithViewController: inputController))
        
        let itemA = NSSplitViewItem(contentListWithViewController: renderingController)
        itemA.minimumThickness = 80
        addSplitViewItem(itemA)
    }
    
}
