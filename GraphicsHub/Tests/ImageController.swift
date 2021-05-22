//
//  ImageController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/18/21.
//

import Cocoa

class ImageController: NSViewController {

    var image: NSImage!
    convenience init(image: NSImage) {
        self.init(nibName: "ImageController", bundle: nil)
        self.image = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let imageHolder = NSImageView()
        imageHolder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageHolder)
        imageHolder.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageHolder.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageHolder.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageHolder.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        imageHolder.imageScaling = .scaleProportionallyDown
        imageHolder.image = image
    }
    
}
