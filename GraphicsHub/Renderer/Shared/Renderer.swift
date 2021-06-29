//
//  Renderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import MetalKit

//import CoreGraphics
//import GLKit
import Accelerate

protocol RendererInfo {
    
    var frame: Int { get set }
    
}

protocol Renderer: RendererInfo {
    
    var name: String { get set}
    
    var device: MTLDevice { get }
    // Holder for renderer's user inputs
    var renderSpecificInputs: [NSView]? { get }
    var inputManager: RendererInputManager { get set }
    
    var size: CGSize { get set }
    
    var recordable: Bool { get }
    var recordPipeline: MTLComputePipelineState! { get set }
    var url: URL? { get set }
    
    var outputImage: MTLTexture! { get }
    // Whether the view should resize with the window
    var resizeable: Bool { get }
    
    var renderPipelineState: MTLRenderPipelineState? { get }
    
    init(device: MTLDevice, size: CGSize)
    
    func synchronizeInputs()
    
    func drawableSizeDidChange(size: CGSize)
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView)
    
    func addAttachments(pipeline: MTLRenderCommandEncoder)
    
    func getDirectory(frameIndex: Int) throws -> URL
}

var defaultSizes: [(Renderer.Type, CGSize)] = [
    (TesterCappedRenderer.self, CGSize(width: 2048, height: 1024)),
    (ConwayRenderer.self, CGSize(width: 2048, height: 2048)),
    (ComplexRenderer.self, CGSize(width: 2048, height: 2058))
]

extension Renderer {
    
    mutating func handleAnimation() {
        if !inputManager.paused {
            self.inputManager.animatorManager.update()
            let frameRange = self.inputManager.animatorManager.frameRange
            if frameRange.1 - frameRange.0 > 0 {
                frame = (frame < frameRange.0) ? frameRange.0 : frame
                if frame > frameRange.1 {
                    frame = frameRange.0
                    inputManager.recording = false
                }
            }
            inputManager.animatorManager.setFrame(frame: frame)
        }
        
    }
    
    func handleDrawing(commandBuffer: MTLCommandBuffer, view: MTKView) {
        if !inputManager.paused {
            draw(commandBuffer: commandBuffer, view: view)
        }
    }

    
    func loadLibrary(name: String) {}
    func record() {}
    func updateAllInputs() {
        (inputManager.inputs as! [InputShell]).forEach {
            _ = $0.didChange
        }
    }
    
    func createTexture(size: CGSize) -> MTLTexture? {
        let renderTargetDescriptor = MTLTextureDescriptor()
        renderTargetDescriptor.pixelFormat = MTLPixelFormat.rgba32Float
        renderTargetDescriptor.textureType = MTLTextureType.type2D
        renderTargetDescriptor.width = Int(size.width)
        renderTargetDescriptor.height = Int(size.height)
        renderTargetDescriptor.storageMode = .private
        renderTargetDescriptor.usage = [.shaderRead, .shaderWrite]
        return device.makeTexture(descriptor: renderTargetDescriptor)
    }
    
    func createReadableTexture(size: CGSize) -> MTLTexture? {
        let renderTargetDescriptor = MTLTextureDescriptor()
        renderTargetDescriptor.pixelFormat = MTLPixelFormat.rgba32Float
        renderTargetDescriptor.textureType = MTLTextureType.type2D
        renderTargetDescriptor.width = Int(size.width)
        renderTargetDescriptor.height = Int(size.height)
        renderTargetDescriptor.storageMode = .managed
        renderTargetDescriptor.usage = [.shaderRead, .shaderWrite]
        return device.makeTexture(descriptor: renderTargetDescriptor)

    }
    
    func createRenderPipelineState(vertexFunction: MTLFunction, fragmentFunction: MTLFunction) throws -> MTLRenderPipelineState {
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.sampleCount = 1
        renderDescriptor.vertexFunction = vertexFunction
        renderDescriptor.fragmentFunction = fragmentFunction
        renderDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        do {
            return try device.makeRenderPipelineState(descriptor: renderDescriptor)
        } catch {
            throw error
        }
    }
    
    func createFunctions(names: String...) -> [MTLFunction?] {
        var functions = [MTLFunction?]()
        let library = device.makeDefaultLibrary()
        for i in names {
            functions.append(library?.makeFunction(name: i))
        }
        return functions
    }
    func getDefaultVertexFunction(library: MTLLibrary) -> MTLFunction? {
        let function = library.makeFunction(name: "copyVertex")
        return function
    }
    func getDefaultFragFunction(library: MTLLibrary) -> MTLFunction? {
        let function = library.makeFunction(name: "copyFragment")
        return function
    }
    func getDefaultCopyFunction(library: MTLLibrary) -> MTLFunction? {
        let function = library.makeFunction(name: "encodeImage")
        return function
    }
    private func getDefaultCopyFunction() -> MTLFunction? {
        let library = device.makeDefaultLibrary()
        let function = library?.makeFunction(name: "encodeImage")
        return function
    }
    func getRecordPipeline() throws -> MTLComputePipelineState {
        let recordFunction = getDefaultCopyFunction()
        do {
            return try device.makeComputePipelineState(function: recordFunction!)
        } catch {
            throw error
        }
    }
    
    func getImageGroupSize() -> MTLSize {
        return MTLSize(width: (Int(size.width) + 7)/8, height: (Int(size.height) + 7)/8, depth: 1)
    }
    func getThreadGroupSize(size: CGSize, ThreadSize: MTLSize) -> MTLSize {
        return MTLSize(width: (Int(size.width) + ThreadSize.width-1)/ThreadSize.width,
                       height: (Int(size.height) + ThreadSize.height-1)/ThreadSize.height,
                       depth: 1)
    }
    func getThreadGroupSize(size: SIMD2<Int32>, ThreadSize: MTLSize) -> MTLSize {
        return MTLSize(width: (Int(size.x) + ThreadSize.width-1)/ThreadSize.width,
                       height: (Int(size.y) + ThreadSize.height-1)/ThreadSize.height,
                       depth: 1)
    }
    func dispatchComputeEncoder(commandBuffer: MTLCommandBuffer,
                                computePipelineState: MTLComputePipelineState,
                                buffers: [MTLBuffer],
                                bytes: [(UnsafeRawPointer, Int)],
                                textures: [MTLTexture],
                                threadGroups: MTLSize,
                                threadGroupSize: MTLSize) {
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        computeEncoder?.setComputePipelineState(computePipelineState)
        for (index, buffer) in buffers.enumerated() {
            computeEncoder?.setBuffer(buffer, offset: 0, index: index)
        }
        for (index, bytes) in bytes.enumerated() {
            computeEncoder?.setBytes(bytes.0, length: bytes.1, index: index + buffers.count)
        }
        computeEncoder?.setTextures(textures, range: 0..<textures.count)
        computeEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder?.endEncoding()
    }
    
    func copyToBuffer(commandBuffer: MTLCommandBuffer?, pixelBuffer: MTLBuffer?) {
        guard let recordPipeline = recordPipeline else { return }
        let copyEncoder = commandBuffer?.makeComputeCommandEncoder()
        copyEncoder?.setComputePipelineState(recordPipeline)
        copyEncoder?.setBuffer(pixelBuffer, offset: 0, index: 0)
        copyEncoder?.setBytes([Int32(outputImage.width)], length: MemoryLayout<Int32>.stride, index: 1)
        copyEncoder?.setTexture(outputImage, index: 0)
        copyEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        copyEncoder?.endEncoding()
    }
    
    mutating func handleRecording(commandBuffer: MTLCommandBuffer, frameIndex: inout Int) {
        if inputManager.recording && !inputManager.paused && recordable {
            do {
                let url = try getDirectory(frameIndex: frameIndex)
                self.url = url
                
//                let texture = blitToTexture(commandBuffer: commandBuffer)
                
                let textureData = blitToBuffer(commandBuffer: commandBuffer)
                let size = self.size
                
                let copiedFrame = frameIndex
                commandBuffer.addCompletedHandler({ _ in
                    Self.saveBuffer(path: url, frame: copiedFrame, data: textureData, width: Int(size.width), height: Int(size.height))
//                    Self.saveImage(path: url, frame: copiedFrame, texture: texture)
                })
                frameIndex += 1
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    static func saveImage(path: URL, frame: Int, texture: MTLTexture) {
        
        if let image = texture.toImage() {
            let imagePath = path.appendingPathComponent("\(frame).tif")
            let localURL = URL(fileURLWithPath: imagePath.path)
            do {
                try image.tiffRepresentation!.write(to: localURL)
            } catch {
                print("Image saving failed: ", error)
            }
        }
    }
    
    static func saveBuffer(path: URL, frame: Int, data: MTLBuffer, width: Int, height: Int) {
        if let image = NSImage.drawBuffer(buffer: data, width: width, height: height) {
            let imagePath = path.appendingPathComponent("\(frame).tif")
            let localURL = URL(fileURLWithPath: imagePath.path)
            do {
                try image.tiffRepresentation!.write(to: localURL)
            } catch {
                print("Image saving failed: ", error)
            }
        } else {
            print("No image")
        }
    }
    
//    private func saveImage(path: URL, frame: Int, commandBuffer: MTLCommandBuffer) {
//        guard let recordPipeline = recordPipeline else { print("No record pipeline"); return }
//        let outputImage = outputImage!
//        let copyEncoder = commandBuffer.makeComputeCommandEncoder()
//        copyEncoder?.setComputePipelineState(recordPipeline)
//        let pixelBuffer = device.makeBuffer(length: RGBA32.size * outputImage.width * outputImage.height, options: .storageModeManaged)
//        copyEncoder?.setBuffer(pixelBuffer, offset: 0, index: 0)
//        copyEncoder?.setBytes([Int32(outputImage.width * 2)], length: MemoryLayout<Int32>.stride, index: 1)
//        copyEncoder?.setTexture(outputImage, index: 0)
//        copyEncoder?.dispatchThreadgroups(getThreadGroupSize(size: CGSize(width: outputImage.width, height: outputImage.height * 2), ThreadSize: MTLSize(width: 8, height: 8, depth: 1)),
//                                          threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
//        copyEncoder?.endEncoding()
//
//        commandBuffer.addCompletedHandler { _ in
//            writeImage(path: path, frame: frame, pixelBuffer: pixelBuffer, imageSize: (outputImage.width, outputImage.height))
//        }
//    }
//
//    private func writeImage(path: URL, frame: Int, pixelBuffer: MTLBuffer?, imageSize: (Int,Int)) {
//        DispatchQueue.global(qos: .background).async {
//            let width = imageSize.0
//            let height = imageSize.1
//
//            let byteCount = Int(width*height*2)
//            let Output = (pixelBuffer!.contents().bindMemory(to: RGBA32.self, capacity: byteCount))
////            for i in 0..<byteCount {
////                let output = Output[i]
////                print(output.redComponent, output.greenComponent, output.blueComponent, output.alphaComponent)
////            }
//            let context2 = CGContext(data: Output, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(8*width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: RGBA32.bitmapInfo)
//            let finalImage = NSImage(cgImage: (context2?.makeImage()!)!, size: NSSize(width: width, height: height))
//            let imagePath = path.appendingPathComponent("\(frame).tiff")
////            try! finalImage.tiffRepresentation!.write(to: imagePath)
//        }
//    }
    
//    private func saveImage(path: URL, frame: Int, commandBuffer: MTLCommandBuffer) {
//        guard let recordPipeline = recordPipeline else { print("No record pipeline"); return }
//        let outputImage = outputImage!
//        let copyEncoder = commandBuffer.makeComputeCommandEncoder()
//        copyEncoder?.setComputePipelineState(recordPipeline)
//        let pixelBuffer = device.makeBuffer(length: RGBA32.size * outputImage.width * outputImage.height, options: .storageModeManaged)
//        copyEncoder?.setBuffer(pixelBuffer, offset: 0, index: 0)
//        copyEncoder?.setBytes([Int32(outputImage.width)], length: MemoryLayout<Int32>.stride, index: 1)
//        copyEncoder?.setTexture(outputImage, index: 0)
//        copyEncoder?.dispatchThreadgroups(getThreadGroupSize(size: CGSize(width: outputImage.width, height: outputImage.height * 2), ThreadSize: MTLSize(width: 8, height: 8, depth: 1)),
//                                          threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
//        copyEncoder?.endEncoding()
//
//        commandBuffer.addCompletedHandler { _ in
//            writeImage(path: path, frame: frame, pixelBuffer: pixelBuffer, imageSize: (outputImage.width, outputImage.height))
//        }
//    }
//
//    private func writeImage(path: URL, frame: Int, pixelBuffer: MTLBuffer?, imageSize: (Int,Int)) {
//        DispatchQueue.global(qos: .background).async {
//            let width = imageSize.0
//            let height = imageSize.1
//
//            let byteCount = Int(width*height*2)
//            let Output = (pixelBuffer!.contents().bindMemory(to: RGBA32.self, capacity: byteCount))
////            for i in 0..<byteCount {
////                let output = Output[i]
////                print(output.redComponent, output.greenComponent, output.blueComponent, output.alphaComponent)
////            }
//            let context2 = CGContext(data: Output, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(8*width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: RGBA32.bitmapInfo)
//            let finalImage = NSImage(cgImage: (context2?.makeImage()!)!, size: NSSize(width: width, height: height))
//            let imagePath = path.appendingPathComponent("\(frame).tiff")
////            print(imagePath)
//            try! finalImage.tiffRepresentation!.write(to: imagePath)
//        }
//
//
//
////        let byteCount = imageSize.0 * imageSize.1 * 2
////        let context = CGContext(data: pixelBuffer?.contents().bindMemory(to: RGBA32.self, capacity: byteCount/2),
////                                width: imageSize.0,
////                                height: imageSize.1,
////                                bitsPerComponent: 8,
////                                bytesPerRow: Int(8*imageSize.0),
////                                space: CGColorSpaceCreateDeviceRGB(),
////                                bitmapInfo: RGBA32.bitmapInfo)
////        let finalImage = NSImage(cgImage: (context?.makeImage()!)!, size: NSSize(width: imageSize.0, height: imageSize.1))
////        try! finalImage.tiffRepresentation?.write(to: path.appendingPathComponent(name + " \(frame).tiff"))
////        print("WRITING", path.appendingPathComponent(name + ".tiff"))
//    }
    
    func blitToTexture(commandBuffer: MTLCommandBuffer) -> MTLTexture {
        let texture = createReadableTexture(size: size)!
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: outputImage, to: texture)
        blitEncoder?.synchronize(resource: texture)
        blitEncoder?.endEncoding()
        return texture
    }
    
    func blitToBuffer(commandBuffer: MTLCommandBuffer) -> MTLBuffer {
        let buffer = device.makeBuffer(length: MemoryLayout<RGBA32>.stride * Int(size.width * size.height), options: .storageModeManaged)!
        let copyEncoder = commandBuffer.makeComputeCommandEncoder()
        copyEncoder?.setComputePipelineState(recordPipeline)
        copyEncoder?.setTexture(outputImage, index: 0)
        copyEncoder?.setBuffer(buffer, offset: 0, index: 0)
        copyEncoder?.setBytes([Int32(size.width)], length: MemoryLayout<Int32>.stride, index: 1)
        copyEncoder?.setBytes([Int32(size.height)], length: MemoryLayout<Int32>.stride, index: 2)
        copyEncoder?.dispatchThreads(MTLSize(width: Int(size.width), height: Int(size.height), depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
        copyEncoder?.endEncoding()
        
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.synchronize(resource: buffer)
        blitEncoder?.endEncoding()
        return buffer
    }
    
}

extension NSImage {
    static func drawBuffer(buffer: MTLBuffer, width: Int, height: Int) -> NSImage? {
        let context = CGContext(data: buffer.contents().bindMemory(to: RGBA32.self, capacity: width * height),
                                width: width,
                                height: height,
                                bitsPerComponent: 8, // AKA MemoryLayout<UInt8>.stride * 8
                                bytesPerRow: RGBA32.size * width,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: RGBA32.bitmapInfo)
        guard let cgImage = context?.makeImage() else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
}

extension MTLTexture {
    
    func toImage() -> NSImage? {
        
        assert (pixelFormat == .rgba32Float)
        let rowByteCount = width * 16
        let bytes = UnsafeMutablePointer<Float>.allocate(capacity: width * height * 4)
        defer {
            bytes.deallocate()
        }
        getBytes(bytes,
                 bytesPerRow: rowByteCount,
                 from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                                 size: MTLSize(width: width, height: height, depth: 1)),
                 mipmapLevel: 0)
        let context = CGContext(data: bytes,
                                width: width,
                                height: height,
                                bitsPerComponent: 32,
                                bytesPerRow: rowByteCount,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let cgImage = context?.makeImage() else { print("Failed making cgImage"); return nil }
    
        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
    
}

extension MTLTexture {
  
//    func bytes() -> UnsafeMutableRawPointer {
//    let width = self.width
//    let height = self.height
//    let rowBytes = self.width * 4
//    let p = malloc(width * height * 4)
//
//    self.getBytes(p!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
//    return p!
//  }
//
//  func toImage() -> CGImage? {
//    let p = bytes()
//
//    let pColorSpace = CGColorSpaceCreateDeviceRGB()
//
//    let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
//    let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
//
//    let selftureSize = self.width * self.height * 4
//    let rowBytes = self.width * 4
//    let provider = (CGDataProvider(dataInfo: nil, data: p, size: selftureSize) { _, _, _ in })!
//    let cgImageRef = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent) // .RenderingIntentDefault
//
//    return cgImageRef
//  }
    
        
        
//        let sourceRowBytes = width * MemoryLayout<SIMD4<Float>>.stride
//        let floatValues = UnsafeMutablePointer<SIMD4<Float>>.allocate(capacity: width * height)
//        defer {
//            floatValues.deallocate()
//        }
//
//        getBytes(floatValues,
//                         bytesPerRow: sourceRowBytes,
//                         from: MTLRegionMake2D(0, 0, width, height),
//                         mipmapLevel: 0)
//
//        let context = CGContext(data: floatValues, width: width, height: height, bitsPerComponent: MemoryLayout<Float>.stride * 8, bytesPerRow: MemoryLayout<SIMD4<Float>>.stride * width, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue)
        // MARK: Stack overflow solution
//        let ciimage = CIImage(mtlTexture: self, options: [CIImageOption.colorSpace : CGColorSpaceCreateDeviceRGB()])
//        let cgImage = ciimage?.cgImage
//        return NSImage(cgImage: cgImage!, size: NSSize(width: width, height: height))
        
        
//        var sourceBuffer = vImage_Buffer(data: floatValues,
//                                         height: vImagePixelCount(height),
//                                         width: vImagePixelCount(width),
//                                         rowBytes: sourceRowBytes)
//
//        var rgbaSourcePlanarBuffers: [vImage_Buffer] = (0 ..< 4).map { _ in
//            guard let buffer = try? vImage_Buffer(width: Int(sourceBuffer.width),
//                                                  height: Int(sourceBuffer.height),
//                                                  bitsPerPixel: UInt32(MemoryLayout<SIMD4<Float>>.stride * 8)) else {
//                                                    fatalError("Error creating source buffers.")
//            }
//
//            return buffer
//        }
//
//
//        let destRowBytes = width
//        let byteValues = malloc(width * height)!
//        var destBuffer = vImage_Buffer(data: byteValues,
//                                       height: vImagePixelCount(height),
//                                       width: vImagePixelCount(width),
//                                       rowBytes: destRowBytes)
//
//        vImageConvert_PlanarFtoPlanar8(&rgbaSourcePlanarBuffers[2], &destBuffer, 1.0, 0.0, vImage_Flags(kvImageNoFlags))
//        let bytesPtr = byteValues.assumingMemoryBound(to: UInt8.self)
//        let provider = CGDataProvider(data: CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
//                                                                        bytesPtr,
//                                                                        width * height,
//                                                                        kCFAllocatorDefault))!
//        let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)!
//        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
//        let cgimage = CGImage(width: width,
//                            height: height,
//                            bitsPerComponent: 8,
//                            bitsPerPixel: 8,
//                            bytesPerRow: destRowBytes,
//                            space: colorSpace,
//                            bitmapInfo: bitmapInfo,
//                            provider: provider,
//                            decode: nil,
//                            shouldInterpolate: false,
//                            intent: .defaultIntent)!
        
//        let image = NSImage(cgImage: context!.makeImage()!, size: NSSize(width: width, height: height))
//        return image
        
        
//        let cgImage = try! sourceBuffer.createCGImage(format: vImage_CGImageFormat.init(bitsPerComponent: MemoryLayout<Float>.stride * 8,
//                                                                                 bitsPerPixel: MemoryLayout<SIMD4<Float>>.stride * 8,
//                                                                                 colorSpace: CGColorSpaceCreateDeviceRGB(),
//                                                                                 bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue | CGBitmapInfo.floatComponents.rawValue))!)
//        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
        
        // MARK: Interactive Solution
        
//        let provider = CGDataProvider(dataInfo: nil,
//                                      data: floatValues,
//                                      size: MemoryLayout<SIMD4<Float>>.stride * width * height,
//                                      releaseData: {_,_,_ in})!
//
//        let cImage = CGImage(width: width,
//                             height: height,
//                             bitsPerComponent: MemoryLayout<Float>.stride * 8,
//                             bitsPerPixel: MemoryLayout<SIMD4<Float>>.stride * 8,
//                             bytesPerRow: MemoryLayout<SIMD4<Float>>.stride * width,
//                             space: CGColorSpaceCreateDeviceRGB(),
//                             bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatInfoMask.rawValue),
//                             provider: provider,
//                             decode: nil,
//                             shouldInterpolate: false,
//                             intent: .defaultIntent)
//        return NSImage(cgImage: cImage!, size: NSSize(width: width, height: height))
//        let content = CGContext(data: floatValues,
//                                width: width,
//                                height: height,
//                                bitsPerComponent: MemoryLayout<Float>.stride * 8,
//                                bytesPerRow: MemoryLayout<SIMD4<Float>>.stride * width,
//                                space: CGColorSpaceCreateDeviceRGB(),
//                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue)
//        return NSImage(cgImage: (content?.makeImage())!, size: NSSize(width: width, height: height))
        
        // MARK: Experimetanl
        
//        vImageConvert_PlanarFtoPlanar8(&sourceBuffer, &destBuffer, 1.0, 0.0, vImage_Flags(kvImageNoFlags))
//        let bytesPtr = byteValues.assumingMemoryBound(to: UInt8.self)
//        let provider = CGDataProvider(data: CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
//                                                                        bytesPtr,
//                                                                        width * height,
//                                                                        kCFAllocatorDefault))!
//        let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)!
//        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
//        let cgimage = CGImage(width: width,
//                            height: height,
//                            bitsPerComponent: 8,
//                            bitsPerPixel: 8,
//                            bytesPerRow: destRowBytes,
//                            space: colorSpace,
//                            bitmapInfo: bitmapInfo,
//                            provider: provider,
//                            decode: nil,
//                            shouldInterpolate: false,
//                            intent: .defaultIntent)!
//
//        let image = NSImage(cgImage: cgimage, size: NSSize(width: width, height: height))
//        return image
        
        // MARK: IDK
        
        
        
        
        
        // MARK: .r32Float
//        let width = texture.width
//        let height = texture.height
//        let sourceRowBytes = width * MemoryLayout<Float>.size
//        let floatValues = UnsafeMutablePointer<Float>.allocate(capacity: width * height)
//        defer {
//            floatValues.deallocate()
//        }
//        texture.getBytes(floatValues,
//                         bytesPerRow: sourceRowBytes,
//                         from: MTLRegionMake2D(0, 0, width, height),
//                         mipmapLevel: 0)
//        var sourceBuffer = vImage_Buffer(data: floatValues,
//                                         height: vImagePixelCount(height),
//                                         width: vImagePixelCount(width),
//                                         rowBytes: sourceRowBytes)
//        let destRowBytes = width
//        let byteValues = malloc(width * height)!
//        var destBuffer = vImage_Buffer(data: byteValues,
//                                       height: vImagePixelCount(height),
//                                       width: vImagePixelCount(width),
//                                       rowBytes: destRowBytes)
//        vImageConvert_PlanarFtoPlanar8(&sourceBuffer, &destBuffer, 1.0, 0.0, vImage_Flags(kvImageNoFlags))
//        let bytesPtr = byteValues.assumingMemoryBound(to: UInt8.self)
//        let provider = CGDataProvider(data: CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
//                                                                        bytesPtr,
//                                                                        width * height,
//                                                                        kCFAllocatorDefault))!
//        let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)!
//        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
//        let image = CGImage(width: width,
//                            height: height,
//                            bitsPerComponent: 8,
//                            bitsPerPixel: 8,
//                            bytesPerRow: destRowBytes,
//                            space: colorSpace,
//                            bitmapInfo: bitmapInfo,
//                            provider: provider,
//                            decode: nil,
//                            shouldInterpolate: false,
//                            intent: .defaultIntent)!
//        let imageRep = NSBitmapImageRep(cgImage: image)
        
//
//
//        let image = NSImage(cgImage: cgimage, size: NSSize(width: width, height: height))
//
////        // read texture as byte array
//        let rowBytes = width * MemoryLayout<Float>.stride
//        let length = rowBytes * self.height
//        let floatValues = UnsafeMutablePointer<Float>.allocate(capacity: width * height)
//        defer {
//            floatValues.deallocate()
//        }
//        let region = MTLRegionMake2D(0, 0, self.width, self.height)
//        self.getBytes(floatValues, bytesPerRow: rowBytes, from: region, mipmapLevel: 0)
//
////        for i in 0...5 {
//
//        }
//
//        // use Accelerate framework to convert from BGRA to RGBA
//        var floatBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: floatBytes),
//                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
//        let float = [Float](repeating: 0, count: length)
//        var rgbaBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: rgbaBytes),
//                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
//        let map: [UInt8] = [2, 1, 0, 3]
//        vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbaBuffer, map, 0)
//
//        // flipping image virtically
//        let flippedBytes = bgraBytes // share the buffer
//        var flippedBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: flippedBytes),
//                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
//        vImageVerticalReflect_ARGB8888(&rgbaBuffer, &flippedBuffer, 0)

        // create CGImage with RGBA
//        let colorScape = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
//
//        guard let data = CFDataCreate(nil, bytes, length) else { return nil }
//        guard let dataProvider = CGDataProvider(data: data) else { return nil }
//        let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes,
//                    space: colorScape, bitmapInfo: bitmapInfo, provider: dataProvider,
//                    decode: nil, shouldInterpolate: true, intent: .defaultIntent
//        )
//        guard let cgImage = cgImage else { return nil }
//        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        
//        assert(self.pixelFormat == .bgra8Unorm)
//
//        // read texture as byte array
//        let rowBytes = self.width * 4
//        let length = rowBytes * self.height
//        let bgraBytes = [UInt8](repeating: 0, count: length)
//        let region = MTLRegionMake2D(0, 0, self.width, self.height)
//        self.getBytes(UnsafeMutableRawPointer(mutating: bgraBytes), bytesPerRow: rowBytes, from: region, mipmapLevel: 0)
//
//        // use Accelerate framework to convert from BGRA to RGBA
//        var bgraBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: bgraBytes),
//                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
//        let rgbaBytes = [UInt8](repeating: 0, count: length)
//        var rgbaBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: rgbaBytes),
//                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
//        let map: [UInt8] = [2, 1, 0, 3]
//        vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbaBuffer, map, 0)
//
//        // flipping image virtically
//        let flippedBytes = bgraBytes // share the buffer
//        var flippedBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: flippedBytes),
//                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: rowBytes)
//        vImageVerticalReflect_ARGB8888(&rgbaBuffer, &flippedBuffer, 0)
//
//        // create CGImage with RGBA
//        let colorScape = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
//        guard let data = CFDataCreate(nil, flippedBytes, length) else { return nil }
//        guard let dataProvider = CGDataProvider(data: data) else { return nil }
//        let cgImage = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes,
//                    space: colorScape, bitmapInfo: bitmapInfo, provider: dataProvider,
//                    decode: nil, shouldInterpolate: true, intent: .defaultIntent)
//        return cgImage
        
}
//
//if let imageRef = texture.toImage() {
//  let image = NSImage(CGImage: imageRef, size: NSSize(width: texture.width, height: texture.height))
//}
