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
        // Do view setup here.
        view.wantsLayer = true
        
        splitView.dividerStyle = .paneSplitter
        minimumThicknessForInlineSidebars = 180
        let itemA = NSSplitViewItem(contentListWithViewController: renderingController)
        itemA.minimumThickness = 80
        addSplitViewItem(itemA)
        
        guard let renderer = renderingController.renderingView.renderer else {
            addSplitViewItem(NSSplitViewItem(contentListWithViewController: TemplateController(color: .systemPink)))
            return
        }
        if let inputs = renderer.renderSpecificInputs {
            addSplitViewItem(NSSplitViewItem(contentListWithViewController: InputDashboardController(renderer: renderer)))
        } else {
            addSplitViewItem(NSSplitViewItem(contentListWithViewController: RenderingInputController(renderer: renderer)))
        }
        
//        let itemB = NSSplitViewItem(contentListWithViewController: InputDashboardController(controller: renderingController))
//        let itemB = NSSplitViewItem(contentListWithViewController: TemplateController(color: .orange))
//        itemB.minimumThickness = 80
//        addSplitViewItem(itemB)
        
        
    }
    
}
