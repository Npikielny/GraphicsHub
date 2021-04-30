//
//  LaunchPad.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import Cocoa

class LaunchPad: NSViewController {
    
    var options: [(String, Renderer.Type)] = [("Tester",TesterBaseRenderer.self),("Tester Capped Renderer",TesterCappedRenderer.self),("Conway's Game of Life",ConwayRenderer.self),("Complex Image Generator",ComplexRenderer.self)]
    
    lazy var graphicsOption: NSCollectionView = {
        let cv = NSCollectionView(frame: .zero)
        let layout = NSCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = padding/2
        layout.minimumInteritemSpacing = padding/2
        layout.sectionInset = NSEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        cv.collectionViewLayout = layout
        
        cv.isSelectable = true
        cv.allowsMultipleSelection = false
        
        cv.delegate = self
        cv.dataSource = self
        
        cv.register(RenderingOption.self, forItemWithIdentifier: RenderingOption.id)
        cv.wantsLayer = true
        cv.layer?.cornerRadius = padding
        cv.layer?.backgroundColor = NSColor.systemGray.cgColor
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundView()
        
        [titleLabel, graphicsOption].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            graphicsOption.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: padding),
            graphicsOption.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
            graphicsOption.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            graphicsOption.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            graphicsOption.widthAnchor.constraint(greaterThanOrEqualToConstant: CGFloat(options.max(by: {$0.0 > $1.0})!.0.count) * 12.5 + 10 + padding * 2)
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
    
}

extension LaunchPad: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        print("SELECTION")
        if let indexPath = indexPaths.first {
            let rendererOptions = options[indexPath.item]
            let defaultSize = (defaultSizes.first { $0.0 == rendererOptions.1})?.1
            guard let device = MTLCreateSystemDefaultDevice() else { print("Failed to create MTLDevice"); return }
            let renderer = rendererOptions.1.init(device: device, size: defaultSize ?? CGSize(width: 1000, height: 600))
            let controller = MainController(size: renderer.size)
//            controller.renderingView.setRenderer(renderer: renderer.1.init(device: controller.renderingView, size: defaultSize ?? CGSize(width: 1000, height: 600)))
            controller.renderingView.setRenderer(renderer: renderer)
            let window = NSWindow(contentViewController: controller)
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
        return options.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: RenderingOption.id, for: indexPath) as! RenderingOption
        cell.titleLabel.string = options[indexPath.item].0
        cell.view.layer?.cornerRadius = 10
        return cell
    }
    
}

extension LaunchPad: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: CGFloat(options[indexPath.item].0.count) * 12.5 + 10, height: 40)
    }
}
