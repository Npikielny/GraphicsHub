//
//  LaunchPad.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import Cocoa

class LaunchPad: NSViewController {
    
    lazy var graphicsOption: NSCollectionView = {
        let cv = NSCollectionView(frame: .zero)
        let layout = NSCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = padding/2
        layout.minimumInteritemSpacing = padding/2
        cv.collectionViewLayout = layout
        
        cv.isSelectable = true
        cv.allowsMultipleSelection = false
        
        cv.delegate = self
        cv.dataSource = self
        
        cv.register(RenderingOption.self, forItemWithIdentifier: RenderingOption.id)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    
    let titleLabel: NSTextView = {
        let tv = NSTextView()
        tv.string = "Graphics Hub"
        tv.font = NSFont.boldSystemFont(ofSize: 30)
        tv.backgroundColor = .clear
        tv.alignment = .center
        tv.isSelectable = false
        tv.isEditable = false
        return tv
    }()
    
    let padding: CGFloat = 20
    
    lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = padding
        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.scrollerStyle = .overlay
//        scrollView.autohidesScrollers = false
        scrollView.hasVerticalRuler = true
        scrollView.hasVerticalScroller = true
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupBackgroundView()
        
        [titleLabel, scrollView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        scrollView.contentView.addSubview(graphicsOption)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            
            graphicsOption.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            graphicsOption.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
            graphicsOption.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            graphicsOption.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            
        ])
    }
    
    fileprivate func setupBackgroundView() {
        let gradient = CAGradientLayer()
        let colors: [CGColor] = [#colorLiteral(red: 1, green: 0.2195897996, blue: 0.09736367315, alpha: 1), #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)]
        gradient.colors = colors
        gradient.locations = (0...colors.count - 1).map { NSNumber(floatLiteral: Double($0) / Double(colors.count)) }
        
        let backgroundView = NSView()
        backgroundView.wantsLayer = true
        backgroundView.layer = gradient
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backgroundView)
        backgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
    
    override func viewWillLayout() {
        graphicsOption.reloadData()
    }
    
}

extension LaunchPad: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first {
            let rendererOptions = RendererCatalog.catalog[indexPath.item]
            
            guard let device = MTLCreateSystemDefaultDevice() else { print("Failed to create MTLDevice"); return }
            let renderer = rendererOptions.1.init(device: device, size: CGSize(width: 512, height: 512))
            
            let controller = MainController(size: renderer.size)
            controller.renderingView.setRenderer(renderer: renderer as! Renderer)
            
            let editor = EditorViewController(controller: controller)
            
            let window = NSWindow(contentViewController: editor)
            let screenSize = NSScreen.main?.frame
            window.setFrame(screenSize ?? NSRect(x: 0, y: 0, width: 1000, height: 600), display: true, animate: false)
            window.title = rendererOptions.0
            window.styleMask = [window.styleMask, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.makeKeyAndOrderFront(nil)
        }
        collectionView.deselectAll(nil)
    }
    
}

extension LaunchPad: NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return RendererCatalog.catalog.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: RenderingOption.id, for: indexPath) as! RenderingOption
        cell.titleLabel.string = RendererCatalog.catalog[indexPath.item].0
        cell.view.layer?.cornerRadius = 10
        return cell
    }
    
}

extension LaunchPad: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: collectionView.frame.width - padding * 2, height: 40)
    }
}
