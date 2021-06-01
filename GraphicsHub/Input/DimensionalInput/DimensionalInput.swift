//
//  DimensionalInput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/19/21.
//

import Cocoa

class DimensionalInput<T>: Animateable<T> {
    
    override var output: T {
        get {
            dimensionalTransform(xSlider.output,ySlider.output)
        }
    }
    
    var dimensionalTransform: (Double, Double) -> T
    
    var getDescription: (T) -> String
    
    override var didChange: Bool {
        if xSlider.didChange || ySlider.didChange {
            draw()
            return true
        }
        return false
    }
    
    typealias OutputType = T
    
    override func reset() {
        xSlider.reset()
        ySlider.reset()
    }
    
    override func collapse() {
        xSlider.collapse()
        ySlider.collapse()
        super.collapse()
    }
    
    override func expand() {
        xSlider.expand()
        ySlider.expand()
        super.collapse()
    }
    
    var xSlider: SliderInput
    var ySlider: SliderInput
    
    internal func setX(value: Double) {
        xSlider.setValue(value: value)
    }
    internal func setY(value: Double) {
        ySlider.setValue(value: value)
    }
    
    var displayView = NSView()
    
    init(name: String, xSlider: SliderInput, ySlider: SliderInput, dimensionalTransform: @escaping (Double, Double) -> T, transform: ((T) -> T)? = nil, getDescription: @escaping (T) -> String) {
        self.xSlider = xSlider
        self.ySlider = ySlider
        self.dimensionalTransform = dimensionalTransform
        self.getDescription = getDescription
        super.init(name: name,
                   defaultValue: dimensionalTransform(xSlider.output, ySlider.output),
                   transform: transform,
                   expectedHeight: 150)
        setupViews()
        draw()
        
    }
    
    func setupViews() {
        displayView.wantsLayer = true
        displayView.layer?.borderWidth = 2
        displayView.layer?.borderColor = .black
        displayView.translatesAutoresizingMaskIntoConstraints = false
        [xSlider, ySlider, displayView].forEach {
            addSubview($0)
            if let _ = $0 as? SliderInput {
                $0.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            }
        }
        NSLayoutConstraint.activate([
            displayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            displayView.topAnchor.constraint(equalTo: topAnchor),
            displayView.widthAnchor.constraint(equalTo: displayView.heightAnchor, multiplier: CGFloat((xSlider.maxValue - xSlider.minValue)/(ySlider.maxValue - ySlider.minValue))),
            
            xSlider.topAnchor.constraint(equalTo: topAnchor),
            xSlider.leadingAnchor.constraint(equalTo: displayView.trailingAnchor, constant: 5),
            
            ySlider.topAnchor.constraint(equalTo: xSlider.bottomAnchor, constant: 5),
            ySlider.leadingAnchor.constraint(equalTo: displayView.trailingAnchor, constant: 5),
            
            displayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            displayView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            displayView.heightAnchor.constraint(lessThanOrEqualToConstant: 100),
            displayView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 1),
            displayView.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func mouseDown(with event: NSEvent) {
        setSliders(event: event)
        draw()
    }
    
    override func mouseDragged(with event: NSEvent) {
        setSliders(event: event)
        draw()
    }
    
    func setSliders(event: NSEvent) {
        let position = self.superview?.convert(event.locationInWindow, to: self.displayView)
        xSlider.setValue(percent: Double((position?.x ?? 0)/(displayView.bounds.size.width)))
        ySlider.setValue(percent: Double((position?.y ?? 0)/(displayView.bounds.size.height)))
    }
    
    internal var indicator = CAShapeLayer()
    internal func draw() {
        let fillPath = CGMutablePath()
        let centerPoint = CGPoint(x: displayView.frame.width * CGFloat(xSlider.percent), y: displayView.frame.height * CGFloat(ySlider.percent))
        fillPath.addArc(center: centerPoint, radius: 5, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
        indicator.path = fillPath
        indicator.strokeColor = NSColor.systemBlue.cgColor
        indicator.lineWidth = 2.5
        indicator.fillColor = .none
        displayView.layer?.addSublayer(indicator)
    }
}

class PointInput: DimensionalInput<CGPoint> {
    
    override var output: CGPoint {
        get {
            dimensionalTransform(xSlider.output,ySlider.output)
        }
        set {
            xSlider.setValue(value: Double(newValue.x))
            ySlider.setValue(value: Double(newValue.y))
        }
    }
    var x: CGFloat { get { CGFloat(xSlider.output) } set { xSlider.setValue(value: Double(newValue)) } }
    var y: CGFloat { get { CGFloat(ySlider.output) } set { ySlider.setValue(value: Double(newValue)) } }
    
    
    override func lerpSet(a: CGPoint, b: CGPoint, p: Double) {
        output = CGPoint(x: (b.x - a.x) * CGFloat(p) + a.x,
                       y: (b.x - a.x) * CGFloat(p) + a.y)
    }
    
    init(name: String, xName: String = "x", yName: String = "y", origin: CGPoint, size: CGSize) {
        super.init(name: name,
                   xSlider: SliderInput(name: xName, minValue: Double(origin.x - size.width/2), currentValue: Double(origin.x), maxValue: Double(origin.x + size.width/2)),
                   ySlider: SliderInput(name: yName, minValue: Double(origin.x - size.width/2), currentValue: Double(origin.x), maxValue: Double(origin.x + size.width/2)),
                   dimensionalTransform: { x, y in CGPoint(x: CGFloat(x), y: CGFloat(y))},
                   getDescription: { point in "(\(point.x), \(point.y)"})
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SizeInput: DimensionalInput<CGSize> {
    
    override var output: CGSize {
        get {
            dimensionalTransform(xSlider.output,ySlider.output)
        }
        set {
            xSlider.setValue(value: Double(newValue.width))
            ySlider.setValue(value: Double(newValue.height))
        }
    }
    
    var width: CGFloat {
        get { CGFloat(xSlider.output) }
        set { xSlider.setValue(value: Double(newValue))}
    }
    var height: CGFloat {
        get { CGFloat(ySlider.output) }
        set { ySlider.setValue(value: Double(newValue))}
    }
    
    override func lerpSet(a: CGSize, b: CGSize, p: Double) {
        output = CGSize(width: (b.width - a.width) * CGFloat(p) + a.width,
                        height: (b.height - a.height) * CGFloat(p) + a.height)
    }
    
    init(name: String, prefix: String?, minSize: CGSize = CGSize(width: 0, height: 0), size: CGSize, maxSize: CGSize) {
        super.init(name: name,
                   xSlider: SliderInput(name: (prefix ?? "") + " Width",
                                        minValue: Double(minSize.width),
                                        currentValue: Double(size.width),
                                        maxValue: Double(maxSize.width)),
                   ySlider: SliderInput(name: (prefix ?? "") + " Height",
                                        minValue: Double(minSize.height),
                                        currentValue: Double(size.height),
                                        maxValue: Double(maxSize.height)),
                   dimensionalTransform: { width, height in CGSize(width: CGFloat(width), height: CGFloat(height))},
                   getDescription: { size in "\(size.width) x \(size.height)"})
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class ScreenSizeInput: SizeInput {
    
    static let screenSize: [CGSize] = [
        CGSize(width: 256, height: 256),
        CGSize(width: 512, height: 512),
        CGSize(width: 1024, height: 1024),
        CGSize(width: 2048, height: 2048),
        CGSize(width: 4096, height: 4096),
        CGSize(width: 8192, height: 8192),
        CGSize(width: 1280, height: 1024),
        CGSize(width: 1600, height: 1200),
        CGSize(width: 1680, height: 1050),
        CGSize(width: 1900, height: 1200),
        CGSize(width: 3840, height: 2160),
        CGSize(width: 3840 * 2, height: 2160 * 2),
        CGSize(width: 3840 * 4, height: 2160 * 4),
    ]
    
    init(name: String, minSize: CGSize = CGSize(width: 0, height: 0), size: CGSize) {
        super.init(name: name, prefix: nil, minSize: minSize, size: size, maxSize: CGSize(width: 3840 * 4, height: 2160 * 4))
        displayView.layer?.addSublayer(indicator)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSliders(event: NSEvent) {
        super.setSliders(event: event)
        let mouseSize = toSize(x: xSlider.percent, y: ySlider.percent)
        if let closestSize = ScreenSizeInput.screenSize.min(by: { distance(size1: mouseSize, size2: $0) < distance(size1: mouseSize, size2: $1) }) {
            xSlider.setValue(value: Double(closestSize.width))
            ySlider.setValue(value: Double(closestSize.height))
        }
    }
    
    private func toPercent(size: CGSize) -> (Double, Double) {
        let dWidth = xSlider.maxValue - xSlider.minValue
        let dHeight = ySlider.maxValue - ySlider.minValue
        return ((Double(size.width) - xSlider.minValue) / dWidth, (Double(size.height) - ySlider.minValue) / dHeight)
    }
    
    private func toSize(x: Double, y: Double) -> CGSize {
        let dWidth = xSlider.maxValue - xSlider.minValue
        let dHeight = ySlider.maxValue - ySlider.minValue
        return CGSize(width: x * dWidth + xSlider.minValue, height: y * dHeight + ySlider.minValue)
    }
    
    private func distance(size1: CGSize, size2: CGSize) -> CGFloat {
        return pow(pow(size2.width - size1.width, 2) + pow(size2.height - size1.height, 2), 0.5)
    }
    
    override internal func draw() {
        indicator.sublayers?.forEach { $0.removeFromSuperlayer() }
        let closestSize = ScreenSizeInput.screenSize.first(where: { $0 == toSize(x: xSlider.percent, y: ySlider.percent)})
        for i in ScreenSizeInput.screenSize {
            let fillPath = CGMutablePath()
            let percent = toPercent(size: i)
            let centerPoint = CGPoint(x: displayView.frame.width * CGFloat(percent.0), y: displayView.frame.height * CGFloat(percent.1))
            fillPath.addArc(center: centerPoint, radius: 2.5, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
            let tempLayer = CAShapeLayer()
            tempLayer.path = fillPath
            tempLayer.strokeColor = i == closestSize ? NSColor.systemGreen.cgColor : NSColor.systemBlue.cgColor
            tempLayer.lineWidth = 2.5
            tempLayer.fillColor = .none
            indicator.addSublayer(tempLayer)
        }
    }
}
