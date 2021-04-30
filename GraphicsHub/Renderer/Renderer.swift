//
//  Renderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import MetalKit

protocol Renderer {
    
    var device: MTLDevice { get }
    // Holder for renderer's user inputs
    var inputView: NSView? { get }
    
    var size: CGSize { get set }
    
    var recordable: Bool { get }
    var outputImage: MTLTexture! { get }
    // Whether the view should resize with the window
    var resizeable: Bool { get }
    
    func drawableSizeDidChange(size: CGSize)
    
    func graphicsPipeline(commandBuffer: MTLCommandBuffer, view: MTKView)
    
    var renderPipelineState: MTLRenderPipelineState? { get }
    
    init(device: MTLDevice, size: CGSize)
    
}

var defaultSizes: [(Renderer.Type, CGSize)] = [
    (TesterCappedRenderer.self, CGSize(width: 2048, height: 1024)),
    (ConwayRenderer.self, CGSize(width: 2048, height: 2048))
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
        renderTargetDescriptor.storageMode = MTLStorageMode.private;
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
}
