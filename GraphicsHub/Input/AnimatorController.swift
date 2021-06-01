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
    
    var inputs: [AnimateableShell]
    
    var plots = [[Int: Double]]()
    var frameDimension = (0,0)
    
    init(inputs: [AnimateableShell]) {
        self.inputs = inputs

        for _ in 0...5 {
            var pts = [Int: Double]()
            for _ in 0..<Int.random(in: 2..<10) {
                pts[Int.random(in: 0...10)] = Double.random(in: -100...100)
            }
            plots.append(pts)
        }

        super.init(nibName: "AnimatorController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var selectorButton: NSButton = {
        let button = NSButton(radioButtonWithTitle: "Input", target: self, action: #selector(setInput))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    @objc func setInput(_ sender: NSButton) {
        
    }
    
    var graphView: NSView = {
        let view = NSView()
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
            selectorButton.topAnchor.constraint(equalTo: view.topAnchor),
            selectorButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectorButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            graphView.topAnchor.constraint(equalTo: selectorButton.bottomAnchor, constant: 15),
            graphView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            graphView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            graphView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15),
        ])
        graphView.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    
    override func viewWillLayout() {
        super.viewWillLayout()
        drawGraphs()
    }
    
    func drawGraphs() {
        graphView.layer?.sublayers?.forEach {
            $0.removeFromSuperlayer()
        }
        let minX = plots.min(by: { plot1, plot2 in
            plot1.min(by: { $0.key < $1.key })?.key ?? 0 < plot2.min(by: { $0.key < $1.key })?.key ?? 0
        })?.min(by: { $0.key < $1.key })?.key
        let maxX = plots.max(by: { plot1, plot2 in
            plot1.max(by: { $0.key < $1.key })?.key ?? 0 < plot2.max(by: { $0.key < $1.key })?.key ?? 0
        })?.max(by: { $0.key < $1.key })?.key
        
        frameDimension = (minX!, maxX!)
        
        
        for (index, plot) in plots.enumerated() {
            drawPlot(seed: index, points: plot.sorted(by: { $0.key < $1.key }))
        }
        
    }
    
    func getDeltaY(points: [Dictionary<Int, Double>.Element]) -> (Double, Double) {
        let minY = points.min(by: { $0.value < $1.value })?.value ?? 0
        let maxY = points.max(by: { $0.value < $1.value })?.value ?? minY
        let deltaY = maxY - minY
        return (deltaY, minY)
    }
    
    func drawPlot(seed: Int, points: [Dictionary<Int, Double>.Element]) {
        
        let data = getDeltaY(points: points)
        let deltaY = data.0
        let minY = data.1
        
        let transform: (Dictionary<Int, Double>.Element) -> CGPoint = { point in
            return CGPoint(x: CGFloat(point.key) / CGFloat(max(self.frameDimension.1 - self.frameDimension.0,1)) * (self.graphView.frame.size.width - 10) + 5,
                           y: CGFloat((point.value - minY) / max(deltaY,0.1)) * (self.graphView.frame.size.height - 10) + 5)
        }
        let curveLayer = CAShapeLayer()
        let path = CGMutablePath()
        path.move(to: transform(points[0]))
        
        var layerPoints = [CAShapeLayer]()
        let addPoint: (CGPoint, Bool) -> () = { point, selected in
            let pointLayer = CAShapeLayer()
            let path = CGMutablePath()
            path.addArc(center: point, radius: 4, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            pointLayer.path = path
            pointLayer.strokeColor = selected ? NSColor.systemYellow.cgColor : NSColor.gray.cgColor
            pointLayer.fillColor = NSColor(vector: self.randomColor(seed: seed)).cgColor
            pointLayer.lineWidth = 2
            layerPoints.append(pointLayer)
        }
        
        for (index, point) in points.enumerated() {
            let location = transform(point)
            path.addLine(to: location)
            if let editingPoint = editingPoint {
                addPoint(location, seed == editingPoint.0 && index == editingPoint.1)
            } else {
                addPoint(location, false)
            }
        }
        curveLayer.path = path
        curveLayer.lineWidth = 3
        curveLayer.strokeColor = NSColor(vector: randomColor(seed: seed)).cgColor
        curveLayer.fillColor = NSColor.clear.cgColor
        graphView.layer?.addSublayer(curveLayer)
        
        layerPoints.forEach { self.graphView.layer?.addSublayer($0) }
        
    }
    
    func randomColor(seed: Int) -> SIMD3<Float> {
        let value = Float(seed * 1282923947237 % 1352624)
        return abs(SIMD3<Float>(cos(value), sin(value), cos(value) * sin(value)))
    }

    override func mouseDown(with event: NSEvent) {
        let location = view.convert(event.locationInWindow, to: graphView)
        handleTouchDown(location: location)
        drawGraphs()
    }
    
    var editingPoint: (Int, Int)?
    func handleTouchDown(location: NSPoint) {
        let distance: (NSPoint, CGPoint) -> CGFloat = { mouse, point in return pow(pow(mouse.x - point.x, 2) + pow(mouse.y - point.y, 2), 0.5) }
        for (plotIndex, plot) in plots.map({ plot in plot.sorted(by: { $0.key < $1.key }) }).enumerated() {
            let data = getDeltaY(points: plot)
            let deltaY = data.0
            let minY = data.1
            let transform: (Dictionary<Int, Double>.Element) -> CGPoint = { point in
                return CGPoint(x: CGFloat(point.key) / CGFloat(max(self.frameDimension.1 - self.frameDimension.0,1)) * self.graphView.frame.size.width,
                               y: CGFloat((point.value - minY) / max(deltaY,0.1)) * self.graphView.frame.size.height)
            }
            for point in plot {
                if distance(location, transform(point)) <= 4 {
                    editingPoint = (plotIndex, point.key)
                    print("NONNULL")
                    return
                }
            }
        }
        print("NULL")
    }
    
    override func mouseDragged(with event: NSEvent) {
        if let editingPoint = editingPoint {
            drawGraphs()
        }
    }
    
    
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
