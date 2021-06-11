//
//  AnimatorController.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/24/21.
//

import Cocoa
import SceneKit

class AnimatorController: NSViewController {

    override var acceptsFirstResponder: Bool { true }
    
    var animatorManager: AnimatorManager
    
    init(inputManager: RendererInputManager) {
        self.animatorManager = AnimatorManager(manager: inputManager)
        super.init(nibName: "AnimatorController", bundle: nil)
        selectorButton = NSPopUpButton(title: "", target: self, action: #selector(setInput))
        selectorButton.translatesAutoresizingMaskIntoConstraints = false
        selectorButton.addItems(withTitles: animatorManager.animations.map({
            ($0.key as! AnimateableInterface).name
        }))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var selectorButton: NSPopUpButton!

    var graphView: GraphView = {
        let view = GraphView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.addSubview(selectorButton)
        view.addSubview(graphView)
        
        NSLayoutConstraint.activate([
            selectorButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            selectorButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            
            graphView.topAnchor.constraint(equalTo: selectorButton.bottomAnchor, constant: 5),
            graphView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            graphView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            graphView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15),
        ])
        graphView.layer?.backgroundColor = NSColor.black.cgColor
        setAnimators()
    }
    
    @objc func setInput(_ sender: NSButton) {
        setAnimators()
    }
    
    private func setAnimators() {
        guard let animators = animatorManager.animations.first(where: { ($0.key as? AnimateableInterface)?.name == selectorButton.selectedItem?.title })?.value else { print("FOund nothin"); return }
        graphView.animators = animators
        graphView.display()
    }
    

    
    // MARK: – Graphs
    func drawGraphs(animators: [InputAnimator]) {
        graphView.animators = animators
        graphView.draw(graphView.frame)
    }
//    func drawGraphs() {
//        if let selectedInput = animatorManager.animations.first(where: { ($0.key as! AnimateableInterface).name == selectorButton.selectedItem?.title })?.key,
//           let selectedInterface = selectedInput as? AnimateableInterface {
//            if let animator = animatorManager.animations[selectedInput] {
//                graphView.animators = [animator]
//            } else {
//                graphView.animators = [SinusoidalAnimator(input: selectedInterface, frameRange: frameDimension)]
//            }
//        }
//            let xRange: (Int, Int) = (min(frameDimension.0, selectedInput.data.min(by: { $0.0 < $1.0 })?.0 ?? frameDimension.0),
//                                      max(frameDimension.1, selectedInput.data.max(by: { $0.0 < $1.0 })?.0 ?? frameDimension.1))
//
//            let current = selectedInput.doubleOutput ?? [0]
//            let yRange: (Double, Double) = (min(selectedInput.data.min(by: { $0.1.min()! < $1.1.min()! })?.1.min() ?? current.min()!, current.min()!),
//                                            max(selectedInput.data.max(by: { $0.1.max()! < $1.1.max()! })?.1.max() ?? current.max()!, current.max()!))
//            drawGridlines(xRange, yRange)
//            drawPlots()
//        } else {
//            print(selectorButton.selectedItem?.title)
//            animatorManager.animations.forEach({
//                print(($0.key as! AnimateableInterface).name)
//                print(($0.key as! AnimateableInterface).name == selectorButton.selectedItem?.title ?? "")
//            })
//        }
//    }
    
//    private func drawGridlines(_ xRange: (Int, Int), _ yRange: (Double, Double)) {
//        // MARK: General Gridlines
//
//        for x in 0...10 {
//            let path = NSBezierPath(rect: graphView.frame)
//            path.move(to: NSPoint(x: graphView.frame.size.width * CGFloat(x) / 10, y: 0))
//            path.line(to: NSPoint(x: graphView.frame.size.width * CGFloat(x) / 10, y: graphView.frame.size.height))
//            path.lineWidth = 1
//            path.stroke()
//        }
//        // MARK: Active Frame Range
//    }
//
//    private func drawPlots() {
//
//    }
//
////    func drawGraphs() {
////        graphView.layer?.sublayers?.forEach {
////            $0.removeFromSuperlayer()
////        }
////        if let input = inputs.first(where: { $0.name == selectorButton.selectedItem?.title}) {
////            let plots = input.data
////
////            if !plots.contains(where: { $0.count > 0 }) { return }
////
////            let minX = (plots.min(by: { plot1, plot2 in
////                plot1.min(by: { $0.key < $1.key })?.key ?? 0 < plot2.min(by: { $0.key < $1.key })?.key ?? 0
////            })?.min(by: { $0.key < $1.key })?.key)!
////            let maxX = (plots.max(by: { plot1, plot2 in
////                plot1.max(by: { $0.key < $1.key })?.key ?? 0 < plot2.max(by: { $0.key < $1.key })?.key ?? 0
////            })?.max(by: { $0.key < $1.key })?.key)!
////
////            frameDimension = (minX, maxX)
////        }
////    }
////
////    func getDeltaY(points: [Dictionary<Int, Double>.Element]) -> (Double, Double) {
////        let minY = points.min(by: { $0.value < $1.value })?.value ?? 0
////        let maxY = points.max(by: { $0.value < $1.value })?.value ?? minY
////        let deltaY = maxY - minY
////        return (deltaY, minY)
////    }
////
////    func drawPlot(seed: Int, points: [Dictionary<Int, Double>.Element]) {
////
////        let data = getDeltaY(points: points)
////        let deltaY = data.0
////        let minY = data.1
////
////        let transform: (Dictionary<Int, Double>.Element) -> CGPoint = { point in
////            return CGPoint(x: CGFloat(point.key) / CGFloat(max(self.frameDimension.1 - self.frameDimension.0,1)) * (self.graphView.frame.size.width - 10) + 5,
////                           y: CGFloat((point.value - minY) / max(deltaY,0.1)) * (self.graphView.frame.size.height - 10) + 5)
////        }
////        let curveLayer = CAShapeLayer()
////        let path = CGMutablePath()
////        path.move(to: transform(points[0]))
////
////        var layerPoints = [CAShapeLayer]()
////        let addPoint: (CGPoint, Bool) -> () = { point, selected in
////            let pointLayer = CAShapeLayer()
////            let path = CGMutablePath()
////            path.addArc(center: point, radius: 4, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
////            pointLayer.path = path
////            pointLayer.strokeColor = selected ? NSColor.systemYellow.cgColor : NSColor.gray.cgColor
////            pointLayer.fillColor = NSColor(vector: self.randomColor(seed: seed)).cgColor
////            pointLayer.lineWidth = 2
////            layerPoints.append(pointLayer)
////        }
////
////        for (index, point) in points.enumerated() {
////            let location = transform(point)
////            path.addLine(to: location)
////            if let editingPoint = editingPoint {
////                addPoint(location, seed == editingPoint.0 && index == editingPoint.1)
////            } else {
////                addPoint(location, false)
////            }
////        }
////        curveLayer.path = path
////        curveLayer.lineWidth = 3
////        curveLayer.strokeColor = NSColor(vector: randomColor(seed: seed)).cgColor
////        curveLayer.fillColor = NSColor.clear.cgColor
////        graphView.layer?.addSublayer(curveLayer)
////
////        layerPoints.forEach { self.graphView.layer?.addSublayer($0) }
////
////    }
////
////    func randomColor(seed: Int) -> SIMD3<Float> {
////        let value = Float(seed * 1282923947237 % 1352624)
////        return abs(SIMD3<Float>(cos(value), sin(value), cos(value) * sin(value)))
////    }
//
//    override func mouseDown(with event: NSEvent) {
//        let location = view.convert(event.locationInWindow, to: graphView)
////        handleTouchDown(location: location)
////        drawGraphs()
//    }
    
//    var editingPoint: (Int, Int)?
//    func handleTouchDown(location: NSPoint) {
//        let distance: (NSPoint, CGPoint) -> CGFloat = { mouse, point in return pow(pow(mouse.x - point.x, 2) + pow(mouse.y - point.y, 2), 0.5) }
//        guard let input = inputs.first(where: { $0.name == selectorButton.selectedItem?.title}) else { return }
//        for (plotIndex, plot) in input.data.map({ plot in plot.sorted(by: { $0.key < $1.key }) }).enumerated() {
//            let data = getDeltaY(points: plot)
//            let deltaY = data.0
//            let minY = data.1
//            let transform: (Dictionary<Int, Double>.Element) -> CGPoint = { point in
//                return CGPoint(x: CGFloat(point.key) / CGFloat(max(self.frameDimension.1 - self.frameDimension.0,1)) * self.graphView.frame.size.width,
//                               y: CGFloat((point.value - minY) / max(deltaY,0.1)) * self.graphView.frame.size.height)
//            }
//            for point in plot {
//                if distance(location, transform(point)) <= 4 {
//                    editingPoint = (plotIndex, point.key)
//                    return
//                }
//            }
//        }
//    }
    
//    override func mouseDragged(with event: NSEvent) {
////        if let editingPoint = editingPoint {
////            drawGraphs()
////        }
//    }
    
    
//    func animateSlider(slider: SliderInput) {
//        let data = slider.keyFrames.sorted(by: {$0.key < $1.key})
////        if data.count == 0 { return }
//
////        let minX = data.first!.key
////        let maxX = data.last!.key
////        let minY = data.max { $1.value > $0.value }?.value ?? 0
////        let maxY = data.max { $1.value > $0.value }?.value ?? minY
//
////        let xDist = maxX - minX
////        let yDist = maxY - minY
//
//        let curveLayer = CAShapeLayer()
//        let path = CGMutablePath()
////        path.move(to: CGPoint(x: 0, y: 0))
////        path.addLine(to: CGPoint(x: 100, y: 100))
////        path.addLine(to: CGPoint(x: 100, y: 200))
//        path.move(to: NSPoint(x: 0, y: view.bounds.size.height * CGFloat.random(in: 0...1)))
//        path.addLine(to: NSPoint(x: view.bounds.size.width / 2, y: 0))
//        path.addLine(to: NSPoint(x: view.bounds.size.width, y: view.bounds.size.height))
//        curveLayer.path = path
//        curveLayer.lineWidth = 3
//        curveLayer.fillColor = NSColor.clear.cgColor
//        curveLayer.strokeColor = NSColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1).cgColor
//        graphView.layer?.addSublayer(curveLayer)
//    }
    
}
