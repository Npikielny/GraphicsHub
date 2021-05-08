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
        
    }
    
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
        textLayer.string = String(Int(FPS))
        textLayer.position = CGPoint(x: 25 + 10, y: 10 + 15)
        textLayer.contentsScale = 1
        textLayer.foregroundColor = .white
        frameLayer.addSublayer(textLayer)
        
        if let renderer = renderer as? CappedRenderer {
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
        
        
        
        layer?.addSublayer(frameLayer)
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
        if let renderPassDescriptor = view.currentRenderPassDescriptor, let renderer = renderer {
            semaphore.wait()
            let commandBuffer = commandQueue.makeCommandBuffer()
            commandBuffer?.addCompletedHandler { [self] commandBuffer in
//                // TODO: This may need to be converted to main thread–depending on how bool-inputs are implemented
//                if renderer.inputManager.recording && renderer.recordable {
//                    if let pixelBuffer = pixelBuffer {
//                        DispatchQueue.main.async {
//                            semaphore.wait()
//                            if let image = toImage(pixelBuffer: pixelBuffer.contents(), imageSize: SIMD2<Int>(renderer.outputImage.width, renderer.outputImage.height)) {
//                                handleWriting(image: image)
//                            }
//                            semaphore.signal()
//                        }
//                        frameIndex += 1
//                    }
//                } else if !renderer.inputManager.recording {
//                    savingPath = nil
//                    frameIndex = 0
//                }
                DispatchQueue.main.async {
                    animateLayer(FPS: 1/(commandBuffer.gpuEndTime - commandBuffer.gpuStartTime))
                }
//                print("Max Potential FPS: ",1/(cp.gpuEndTime - cp.gpuStartTime))
                self.semaphore.signal()
            }
            renderer.inputManager.handlePerFrameChecks()
            
            if let commandBuffer = commandBuffer {
                renderer.synchronizeInputs()
                renderer.draw(commandBuffer: commandBuffer, view: self)
                renderer.handleRecording(commandBuffer: commandBuffer, frame: &frameIndex)
//                if renderer.inputManager.recording && renderer.recordable {
//                    if let pixelBuffer = pixelBuffer {
//                        renderer.copyToBuffer(commandBuffer: commandBuffer, pixelBuffer: pixelBuffer)
//                    } else {
//                        self.pixelBuffer = device?.makeBuffer(length: renderer.outputImage.width * renderer.outputImage.height * MemoryLayout<RGBA32>.stride, options: .storageModeManaged)
//                        renderer.copyToBuffer(commandBuffer: commandBuffer, pixelBuffer: pixelBuffer!)
//                    }
//                }
            }
            
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            if let pipeline = renderer.renderPipelineState {
                renderEncoder?.setRenderPipelineState(pipeline)
            } else {
                renderEncoder?.setRenderPipelineState(renderPipelineState)
            }
            renderEncoder?.setFragmentTexture(renderer.outputImage, index: 0)
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder?.endEncoding()
            
            commandBuffer?.present(view.currentDrawable!)
            commandBuffer?.commit()
            
        }
    }
    
    func toImage(pixelBuffer: UnsafeMutableRawPointer, imageSize: SIMD2<Int>) -> NSImage? {
        let byteCount = Int(imageSize.x * imageSize.y * 2)
        let context = CGContext(data: pixelBuffer, width: imageSize.x, height: imageSize.y, bitsPerComponent: 8, bytesPerRow: Int(8*imageSize.x), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: RGBA32.bitmapInfo)
        let finalImage = NSImage(cgImage: (context?.makeImage()!)!, size: NSSize(width: imageSize.x, height: imageSize.y))
//        let byteCount = imageSize.x * imageSize.y * 2
//        let output = (pixelBuffer.contents().bindMemory(to: RGBA32.self, capacity: byteCount))
//
//        let context = CGContext(data: output,
//                                width: imageSize.x,
//                                height: imageSize.y,
//                                bitsPerComponent: 8,
//                                bytesPerRow: Int(8 * imageSize.x),
//                                space: CGColorSpaceCreateDeviceRGB(),
//                                bitmapInfo: RGBA32.bitmapInfo)
//        let image = context!.makeImage()
//        let finalImage = NSImage(cgImage: image!, size: NSSize(width: CGFloat(imageSize.x), height: CGFloat(imageSize.y)))
        return finalImage
//        return nil
    }
    
    func handleWriting(image: NSImage) {
        if let _ = savingPath {} else {
            createDirectory()
        }
        do {
            let url = savingPath!.appendingPathComponent(renderer!.name +  " \(frameIndex).tiff")
            try image.tiffRepresentation?.write(to: url)
//            } else {
//                print(savingPath)
//                print("Failed saving \(frameIndex)–couldn't make URL")
//            }
        } catch {
            print(savingPath)
            print("Failed saving \(frameIndex)", error)
        }
    }
    
    func createDirectory() -> URL? {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        savingPath = desktopURL
        return desktopURL
//        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
//        let desktopDirectory = paths[0]
//        let docURL = URL(string: desktopDirectory)!
//        let dataPath = docURL.appendingPathComponent((renderer?.name ?? ""))
//        if !FileManager.default.fileExists(atPath: dataPath.path) {
//            do {
//                try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
//                self.savingPath = desktopDirectory+"/"+dataPath.path
//                return self.savingPath!
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//        self.savingPath = desktopDirectory+"/"+dataPath.path
//        return self.savingPath
    }
    
}

extension RenderingView {
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
