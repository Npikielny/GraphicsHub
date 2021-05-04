//
//  RenderingView.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import MetalKit

class RenderingView: MTKView {
    
    let commandQueue: MTLCommandQueue
    let semaphore = DispatchSemaphore(value: 1)
    
    var renderPipelineState: MTLRenderPipelineState!
    
    var renderer: Renderer?
    
    var pixelBuffer: MTLBuffer?
    
    var savingPath: String?
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
    
    func draw(in view: MTKView) {
        if let renderPassDescriptor = view.currentRenderPassDescriptor, let renderer = renderer {
            semaphore.wait()
            let commandBuffer = commandQueue.makeCommandBuffer()
            commandBuffer?.addCompletedHandler { [self] _ in
                if renderer.inputManager.recording && renderer.recordable {
                    if let pixelBuffer = pixelBuffer {
                        if let image = toImage(pixelBuffer: pixelBuffer, imageSize: SIMD2<Int>(renderer.outputImage.width, renderer.outputImage.height)) {
                            // TODO: Handle writing files
                            frameIndex += 1
                        }
                    }
                } else if !renderer.inputManager.recording {
                    savingPath = nil
                    frameIndex = 0
                }
                self.semaphore.signal()
            }
            
            if let commandBuffer = commandBuffer {
                renderer.synchronizeInputs()
                renderer.draw(commandBuffer: commandBuffer, view: self)
                if renderer.inputManager.recording && renderer.recordable {
                    if let pixelBuffer = pixelBuffer {
                        renderer.copyToBuffer(commandBuffer: commandBuffer, pixelBuffer: pixelBuffer)
                    } else {
                        self.pixelBuffer = device?.makeBuffer(length: renderer.outputImage.width * renderer.outputImage.height * MemoryLayout<RGBA32>.stride, options: .storageModeManaged)
                        renderer.copyToBuffer(commandBuffer: commandBuffer, pixelBuffer: pixelBuffer!)
                    }
                }
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
    
    func toImage(pixelBuffer: MTLBuffer, imageSize: SIMD2<Int>) -> NSImage? {
        let byteCount = imageSize.x * imageSize.y * 2
        let output = (pixelBuffer.contents().bindMemory(to: RGBA32.self, capacity: byteCount))

        let context = CGContext(data: output,
                                width: imageSize.x,
                                height: imageSize.y,
                                bitsPerComponent: 8,
                                bytesPerRow: Int(8 * imageSize.x),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: RGBA32.bitmapInfo)
        let image = context!.makeImage()
        let finalImage = NSImage(cgImage: image!, size: NSSize(width: CGFloat(imageSize.x), height: CGFloat(imageSize.y)))
        return finalImage
//        return nil
    }
    
    func handleWriting(image: NSImage) {
        do {
            if let url = URL(string: savingPath!+"/\(frame).tiff") {
                try image.tiffRepresentation?.write(to: url)
            } else {
                print("Failed saving \(frame)–couldn't make URL")
            }
        } catch {
            print("Failed saving \(frame)", error)
        }
    }
    
    func createDirectory() {
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
        let desktopDirectory = paths[0]
        let docURL = URL(string: desktopDirectory)!
        let dataPath = docURL.appendingPathComponent((renderer?.name ?? "") + NSDate().description)
        if !FileManager.default.fileExists(atPath: dataPath.path) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
                self.savingPath = desktopDirectory+"/"+dataPath.path
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
}
