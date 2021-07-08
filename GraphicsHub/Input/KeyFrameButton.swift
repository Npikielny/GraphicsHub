//
//  KeyFrameButton.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/7/21.
//

import Cocoa

class KeyFrameButton: NSButton {
    
    static let selected: NSImage = {
        let image = NSImage(named: "KeyFrame-Selected")!
        image.isTemplate = false
        return image
    }()
    
    static let unselected: NSImage = {
        let image = NSImage(named: "KeyFrame-Unselected")!
        image.isTemplate = false
        return image
    }()
    
    var currentState = false { didSet { setImage() } }
    
    init(startingState: Bool = false, target: AnyObject?, action: Selector?) {
        let size = KeyFrameButton.selected.size
        super.init(frame: NSRect(x: 0, y: 0, width: size.width, height: size.height))
        self.target = target
        self.action = action
        
        imageScaling = .scaleProportionallyDown
        bezelStyle = .smallSquare
        setImage()
    }
    
    func setImage() {
        image = currentState ? KeyFrameButton.selected : KeyFrameButton.unselected
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
