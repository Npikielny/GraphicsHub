//
//  AppDelegate.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let controller = LaunchPad(nibName: "LaunchPad", bundle: nil)
        window.contentViewController = controller
        window.styleMask = [window.styleMask, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "LaunchPad"
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

