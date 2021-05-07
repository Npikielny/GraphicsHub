//
//  Renderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import MetalKit

protocol Renderer {
    
    var name: String { get set}
    
    var device: MTLDevice { get }
    // Holder for renderer's user inputs
    var renderSpecificInputs: [NSView]? { get }
    var inputManager: InputManager { get set }
    func synchronizeInputs()
    
    var size: CGSize { get set }
    
    var recordable: Bool { get }
    var recordPipeline: MTLComputePipelineState! { get set }
    
    var outputImage: MTLTexture! { get }
    // Whether the view should resize with the window
    var resizeable: Bool { get }
    
    func drawableSizeDidChange(size: CGSize)
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView)
    
    var renderPipelineState: MTLRenderPipelineState? { get }
    
    init(device: MTLDevice, size: CGSize)
    
}

var defaultSizes: [(Renderer.Type, CGSize)] = [
    (TesterCappedRenderer.self, CGSize(width: 2048, height: 1024)),
    (ConwayRenderer.self, CGSize(width: 2048, height: 2048)),
    (ComplexRenderer.self, CGSize(width: 2048, height: 2058))
]

extension Renderer {
    func loadLibrary(name: String) {}
    func record() {}
    func createTexture(size: CGSize) -> MTLTexture? {
        let renderTargetDescriptor = MTLTextureDescriptor()
        renderTargetDescriptor.pixelFormat = MTLPixelFormat.rgba32Float
        renderTargetDescriptor.textureType = MTLTextureType.type2D
        renderTargetDescriptor.width = Int(size.width)
        renderTargetDescriptor.height = Int(size.height)
        renderTargetDescriptor.storageMode = MTLStorageMode.managed;
        renderTargetDescriptor.usage = [MTLTextureUsage.shaderRead, MTLTextureUsage.shaderWrite]
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
                                buffers: [(MTLBuffer, Int)],
                                bytes: [(UnsafeRawPointer, Int, Int)],
                                textures: [MTLTexture],
                                threadGroups: MTLSize,
                                threadGroupSize: MTLSize) {
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        computeEncoder?.setComputePipelineState(computePipelineState)
        for i in buffers {
            computeEncoder?.setBuffer(i.0, offset: 0, index: i.1)
        }
        for i in bytes {
            computeEncoder?.setBytes(i.0, length: i.1, index: i.2)
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
    
    func handleRecording(commandBuffer: MTLCommandBuffer, frame: inout Int) {
        if inputManager.recording && recordable {
            let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            saveImage(path: desktopURL, frame: frame, commandBuffer: commandBuffer)
            frame += 1
        }
    }
    
    private func saveImage(path: URL, frame: Int, commandBuffer: MTLCommandBuffer) {
        guard let recordPipeline = recordPipeline else { print("No record pipeline"); return }
        let outputImage = outputImage!
        let copyEncoder = commandBuffer.makeComputeCommandEncoder()
        copyEncoder?.setComputePipelineState(recordPipeline)
        let pixelBuffer = device.makeBuffer(length: MemoryLayout<RGBA32>.stride * outputImage.width * outputImage.height * 2, options: .storageModeManaged)
        copyEncoder?.setBuffer(pixelBuffer, offset: 0, index: 0)
        copyEncoder?.setBytes([Int32(outputImage.width * 2)], length: MemoryLayout<Int32>.stride, index: 1)
        copyEncoder?.setTexture(outputImage, index: 0)
        copyEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        copyEncoder?.endEncoding()
        
        commandBuffer.addCompletedHandler { _ in
            writeImage(path: path, frame: frame, pixelBuffer: pixelBuffer, imageSize: (outputImage.width, outputImage.height))
        }
    }
    
    private func writeImage(path: URL, frame: Int, pixelBuffer: MTLBuffer?, imageSize: (Int,Int)) {
//        let byteCount = imageSize.0 * imageSize.1 * 2
//        let context = CGContext(data: pixelBuffer?.contents().bindMemory(to: RGBA32.self, capacity: byteCount/2),
//                                width: imageSize.0,
//                                height: imageSize.1,
//                                bitsPerComponent: 8,
//                                bytesPerRow: Int(8*imageSize.0),
//                                space: CGColorSpaceCreateDeviceRGB(),
//                                bitmapInfo: RGBA32.bitmapInfo)
//        let finalImage = NSImage(cgImage: (context?.makeImage()!)!, size: NSSize(width: imageSize.0, height: imageSize.1))
//        try! finalImage.tiffRepresentation?.write(to: path.appendingPathComponent(name + " \(frame).tiff"))
//        print("WRITING", path.appendingPathComponent(name + ".tiff"))
        let width = imageSize.0
        let height = imageSize.1
        
        let byteCount = Int(width*height*2)
        let Output = (pixelBuffer!.contents().bindMemory(to: RGBA32.self, capacity: byteCount))
        for i in 0..<byteCount {
            Output[i] = RGBA32(red: 0, green: 0, blue: 0, alpha: 255)
        }
        let context2 = CGContext(data: Output, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(8*width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: RGBA32.bitmapInfo)
        let finalImage = NSImage(cgImage: (context2?.makeImage()!)!, size: NSSize(width: width, height: height))
        try! finalImage.tiffRepresentation?.write(to: path.appendingPathComponent(name + "-\(frame).tiff"))
    }
}
