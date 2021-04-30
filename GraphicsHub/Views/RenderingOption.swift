//
//  RenderingOption.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import Cocoa

class RenderingOption: NSCollectionViewItem {

    static let id = NSUserInterfaceItemIdentifier(rawValue: "RenderingOption")
    
    let titleLabel: NSText = {
        let text = NSText()
        text.translatesAutoresizingMaskIntoConstraints = false
        text.isEditable = false
        text.isSelectable = false
        text.isFieldEditor = false
        text.backgroundColor = NSColor.clear
        text.font = .boldSystemFont(ofSize: 15)
        text.alignment = .center
        return text
    }()
    
    let coverView: NSView = {
        let vw = NSView()
        vw.wantsLayer = true
        vw.layer?.backgroundColor = NSColor.clear.cgColor
        vw.translatesAutoresizingMaskIntoConstraints = false
        return vw
    }()
    
    let padding: CGFloat = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.red.cgColor
        
        view.addSubview(titleLabel)
        view.addSubview(coverView)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            titleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            
            coverView.topAnchor.constraint(equalTo: view.topAnchor),
            coverView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            coverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
}
