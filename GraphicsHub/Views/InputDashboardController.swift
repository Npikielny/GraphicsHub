//
//  InputDashboardController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

import Cocoa

class InputDashboardController: NSSplitViewController {
    
    var renderingInputs = [NSView]()
    private var rendererInputView: [NSView]
    
    init(renderer: Renderer) {
        self.rendererInputView = renderer.renderSpecificInputs!
        super.init(nibName: "InputDashboardController", bundle: nil)
//        if let _ = controller.renderingView.renderer as? CappedRenderer {
//            // Add capped renderer stuffs
//        } else {
//
//        }
//        self.rendererInputView = controller.renderingView.renderer?.inputView
//        let renderingInputController = NSSplitViewItem(contentListWithViewController: TemplateController(color: .red))
        let renderingInputController = NSSplitViewItem(contentListWithViewController: RenderingInputController(renderer: renderer))
        renderingInputController.minimumThickness = 80
        addSplitViewItem(renderingInputController)
        
//        let rendererInputController = NSSplitViewItem(contentListWithViewController: TemplateController(color: .green))
        let rendererInputController = NSSplitViewItem(contentListWithViewController: InputController(inputs: renderer.renderSpecificInputs!))
        rendererInputController.minimumThickness = 80
        addSplitViewItem(rendererInputController)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        
        splitView.isVertical = false
        
        splitView.dividerStyle = .paneSplitter
        minimumThicknessForInlineSidebars = 180
//        let itemA = NSSplitViewItem(contentListWithViewController: TemplateController(color: .purple))
//        itemA.minimumThickness = 80
//        addSplitViewItem(itemA)
//
//        let itemB = NSSplitViewItem(contentListWithViewController: TemplateController(color: .orange))
//        itemB.minimumThickness = 80
//        addSplitViewItem(itemB)
//
////        view.wantsLayer = true
////
////        splitView.dividerStyle = .paneSplitter
////        splitView.isVertical = false
////        minimumThicknessForInlineSidebars = 180
////        let itemA = NSSplitViewItem(contentListWithViewController: TemplateController(color: .red))
////        itemA.minimumThickness = 80
////        addSplitViewItem(itemA)
////
////        let itemB = NSSplitViewItem(contentListWithViewController: TemplateController(color: .green))
////        itemB.minimumThickness = 80
////        addSplitViewItem(itemA)
////        if let rendererInputView = rendererInputView {
////            let partnerController = InputController(inputs: rendererInputView)
////            let itemB = NSSplitViewItem(contentListWithViewController: partnerController)
////            itemB.minimumThickness = 80
////            addSplitViewItem(itemB)
////        } else {
////            let itemB = NSSplitViewItem(contentListWithViewController: TemplateController(color: .green))
////            itemB.minimumThickness = 80
////            addSplitViewItem(itemA)
////        }
    }
    
}
