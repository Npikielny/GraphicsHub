//
//  InputManager.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/4/21.
//

import Cocoa

protocol InputManager {
    var inputs: [NSView] { get set }
    
    func handlePerFrameChecks()
    
    func keyDown(event: NSEvent)
    func mouseDown(event: NSEvent)
    func mouseDragged(event: NSEvent)
    func mouseMoved(event: NSEvent)
    func scrollWheel(event: NSEvent)
}
