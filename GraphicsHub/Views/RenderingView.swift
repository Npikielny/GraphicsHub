//
//  RenderingView.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import MetalKit

class RenderingView: MTKView {
    
    override var acceptsFirstResponder: Bool { true }
    
    let commandQueue: MTLCommandQueue
    let semaphore = DispatchSemaphore(value: 1)
    
    var renderPipelineState: MTLRenderPipelineState!
    
    var renderer: Renderer?
    
    var pixelBuffer: MTLBuffer?
    
    var savingPath: URL?
    var frameIndex: Int = 0
    
    init(size: CGSize) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to find metal device")
        }
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed command queue")
        }
        self.commandQueue = commandQueue
        
        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "copyVertex")!
        let fragmentFunction = library.makeFunction(name: "copyFragment")!
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.sampleCount = 1
        renderDescriptor.vertexFunction = vertexFunction
        renderDescriptor.fragmentFunction = fragmentFunction
        renderDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderDescriptor)
        
        super.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size), device: device)
        
        colorspace = CGColorSpace(name: CGColorSpace.linearSRGB)
        colorPixelFormat = .rgba16Float
        sampleCount = 1
        translatesAutoresizingMaskIntoConstraints = false
        
        self.delegate = self
        
        timer = Timer.scheduledTimer(withTimeInterval: 1/120, repeats: true, block: { timer in
            if self.renderer?.inputManager.recording ?? false {
                self.timeElapsed += 1/120
            } else {
                self.timeElapsed = 0
            }
        })
        
    }
    var timeElapsed: Double = 0
    var timer: Timer!
    
    var frameLayer = CAShapeLayer()
    func animateLayer(FPS: Double) {
        frameLayer.removeFromSuperlayer()
        frameLayer = CAShapeLayer()
        let fillPath = CGMutablePath()
        let centerPoint = CGPoint(x: 25 + 10, y: 25 + 10)
        fillPath.addArc(center: centerPoint, radius: 25, startAngle: 0 + CGFloat.pi/2, endAngle: CGFloat.pi * 2 + CGFloat.pi/2, clockwise: false)
        frameLayer.path = fillPath
        frameLayer.strokeColor = .none
        frameLayer.fillColor = .black
        
        let path = CGMutablePath()
        let percent = min(1, FPS/200)
        let final = CGFloat.pi*2 * CGFloat(percent)
        let strokeLayer = CAShapeLayer()
        path.addArc(center: centerPoint, radius: 25, startAngle: 0 + CGFloat.pi/2, endAngle: final + CGFloat.pi/2, clockwise: false)
        strokeLayer.path = path
        strokeLayer.fillColor = .none
        
        let colors: [NSColor] = [.red, .orange, .green]
        
        let value = percent * Double(colors.count - 1)
        let minColor = min(max(Int(value),0),1)
        let percentInRange = CGFloat(value - floor(value))
        strokeLayer.strokeColor = NSColor(red: colors[minColor].redComponent * percentInRange + colors[minColor + 1].redComponent * (1 - percentInRange),
                                          green: colors[minColor].greenComponent * percentInRange + colors[minColor + 1].greenComponent * (1 - percentInRange),
                                          blue: colors[minColor].blueComponent * percentInRange + colors[minColor + 1].blueComponent * (1 - percentInRange),
                                          alpha: 1).cgColor
        
        strokeLayer.lineWidth = 5.0
        frameLayer.addSublayer(strokeLayer)
        
        let textLayer = CATextLayer()
        textLayer.font = NSFont.boldSystemFont(ofSize: 15)
        textLayer.fontSize = 20
        textLayer.alignmentMode = .center
        textLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        textLayer.position = CGPoint(x: 25 + 10, y: 10 + 15)
        textLayer.contentsScale = 1
        textLayer.foregroundColor = .white
        frameLayer.addSublayer(textLayer)
        
        if let renderer = renderer as? AntialiasingRenderer {
            textLayer.string = String(renderer.frame)
            
            let frameText = CATextLayer()
            frameText.font = NSFont.boldSystemFont(ofSize: 15)
            frameText.fontSize = 10
            frameText.alignmentMode = .center
            frameText.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            frameText.string = String(renderer.renderPasses)
            frameText.position = CGPoint(x: 25 + 10, y: 0)
            frameText.contentsScale = 1
            frameText.foregroundColor = .white
            frameLayer.addSublayer(frameText)
        } else {
            textLayer.string = String(Int(FPS))
            
            if let renderer = renderer {
                let frameText = CATextLayer()
                frameText.font = NSFont.boldSystemFont(ofSize: 15)
                frameText.fontSize = 10
                frameText.alignmentMode = .center
                frameText.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
                frameText.string = String(renderer.frame)
                frameText.position = CGPoint(x: 25 + 10, y: 0)
                frameText.contentsScale = 1
                frameText.foregroundColor = .white
                frameLayer.addSublayer(frameText)
            }
        }
        layer?.addSublayer(frameLayer)
    }
    
    var recordLayer = CAShapeLayer()
    func recordingProgress() {
        recordLayer.removeFromSuperlayer()
        guard let renderer = renderer else { return }
        let frameDomain = renderer.inputManager.animatorManager.frameDomain
        if frameDomain.1 == frameDomain.0 { return }
        if !renderer.inputManager.recording { return }
        
        recordLayer = CAShapeLayer()
        let fillPath = CGMutablePath()
        let centerPoint = CGPoint(x: 75 + 20, y: 25 + 10)
        fillPath.addArc(center: centerPoint, radius: 25, startAngle: 0 + CGFloat.pi/2, endAngle: CGFloat.pi * 2 + CGFloat.pi/2, clockwise: false)
        recordLayer.path = fillPath
        recordLayer.strokeColor = .none
        recordLayer.fillColor = .black
        
        let path = CGMutablePath()
        let percent: Double = {
            if frameDomain.1 - frameDomain.0 == 0 {
                return 1
            } else {
                return 1 - Double(frameDomain.1 - renderer.inputManager.frame) / Double(frameDomain.1 - frameDomain.0 + 1)
            }
        }()
        let final = CGFloat.pi * 2 * CGFloat(percent)
        let strokeLayer = CAShapeLayer()
        path.addArc(center: centerPoint, radius: 25, startAngle: 0 + CGFloat.pi/2, endAngle: final + CGFloat.pi/2, clockwise: false)
        strokeLayer.path = path
        strokeLayer.fillColor = .none
        
        let colors: [NSColor] = [.red, .orange, .green]
        
        let value = percent * Double(colors.count - 1)
        let minColor = min(max(Int(value),0),1)
        let percentInRange = CGFloat(value - floor(value))
        strokeLayer.strokeColor = NSColor(red: colors[minColor].redComponent * percentInRange + colors[minColor + 1].redComponent * (1 - percentInRange),
                                          green: colors[minColor].greenComponent * percentInRange + colors[minColor + 1].greenComponent * (1 - percentInRange),
                                          blue: colors[minColor].blueComponent * percentInRange + colors[minColor + 1].blueComponent * (1 - percentInRange),
                                          alpha: 1).cgColor
        
        strokeLayer.lineWidth = 5.0
        recordLayer.addSublayer(strokeLayer)
        
        let textLayer = CATextLayer()
        textLayer.font = NSFont.boldSystemFont(ofSize: 15)
        textLayer.fontSize = 15
        textLayer.alignmentMode = .center
        textLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        textLayer.position = CGPoint(x: 75 + 20, y: 10 + 10)
        textLayer.contentsScale = 1
        textLayer.foregroundColor = .white
        let time = Double(timeElapsed) * Double(frameDomain.1 - frameDomain.0 + 1) / (Double(renderer.inputManager.frame - frameDomain.0) + 0.01) - Double(timeElapsed)
        let hours = time / 60 / 60
        let minutes = Int(time) % (60 * 60) / 60
        let seconds = Int(time) % 60
        if hours > 0 {
            textLayer.string = "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            textLayer.string = "\(minutes)m \(seconds)s"
        } else {
            textLayer.string = "\(seconds)s"
        }
        recordLayer.addSublayer(textLayer)
        
        layer?.addSublayer(recordLayer)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setRenderer(renderer: Renderer) {
        if let currentRenderer = self.renderer {
            currentRenderer.renderSpecificInputs?[0].window?.close()
        }
        self.renderer = renderer
        mtkView(self, drawableSizeWillChange: renderer.size)
        self.autoResizeDrawable = renderer.resizeable
        // FIXME: THIS DOESN'T WORK
//        if !renderer.resizeable {
//            self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: renderer.size.width/renderer.size.height).isActive = true
//        }
    }
}

extension RenderingView: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard let renderer = renderer else { return }
        renderer.drawableSizeDidChange(size: size)
    }
    // TODO: DONT DRAW UNLESS NECESSARY!
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor, let renderer = renderer else { return }
        semaphore.wait()
        if !renderer.initialized {
            renderer.setupResources(commandQueue: commandQueue, semaphore: semaphore)
            return
        }
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.addCompletedHandler { [self] commandBuffer in
            DispatchQueue.main.async {
                if !renderer.inputManager.paused {
                    animateLayer(FPS: 1/(commandBuffer.gpuEndTime - commandBuffer.gpuStartTime))
                } else {
                    animateLayer(FPS: 0)
                }
                recordingProgress()
            }
            self.semaphore.signal()
        }
        renderer.inputManager.handlePerFrameChecks()
        if let commandBuffer = commandBuffer {
            self.renderer!.handleAnimation()
            renderer.synchronizeInputs()
            renderer.updateAllInputs()
            renderer.draw(commandBuffer: commandBuffer, view: self)
            self.renderer!.handleRecording(commandBuffer: commandBuffer, frameIndex: &frameIndex)
        }
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        if let pipeline = renderer.renderPipelineState {
            renderEncoder?.setRenderPipelineState(pipeline)
            renderer.addAttachments(pipeline: renderEncoder!)
        } else {
            renderEncoder?.setRenderPipelineState(renderPipelineState)
            renderEncoder?.setFragmentTexture(renderer.outputImage, index: 0)
        }
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
    }
    
}

extension RenderingView {
    override func flagsChanged(with event: NSEvent) {
        renderer?.inputManager.flagsChanged(event: event)
    }
    override func mouseDown(with event: NSEvent) {
        renderer?.inputManager.mouseDown(event: event)
    }
    override func mouseDragged(with event: NSEvent) {
        renderer?.inputManager.mouseDragged(event: event)
    }
    override func mouseMoved(with event: NSEvent) {
        renderer?.inputManager.mouseMoved(event: event)
    }
    override func keyDown(with event: NSEvent) {
        renderer?.inputManager.keyDown(event: event)
    }
    override func scrollWheel(with event: NSEvent) {
        renderer?.inputManager.scrollWheel(event: event)
    }
}
