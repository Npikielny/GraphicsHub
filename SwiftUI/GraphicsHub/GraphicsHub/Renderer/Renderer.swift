//
//  Renderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 9/7/21.
//

import MetalKit


class Renderer: NSObject {
    
    var size: CGSize
    var dispatchSize = MTLSize(width: 8, height: 8, depth: 1)
    var output: MTLTexture!
    lazy var renderPipeline: MTLRenderPipelineState = Renderer.defaultRenderPipeline
    
    static var device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    var semaphore = DispatchSemaphore(value: 1)
    
    var frame: Int = 0
    
    required init(size: CGSize) {
        self.size = size
        commandQueue = Renderer.device.makeCommandQueue()!
        super.init()
    } // FIXME: Add attributes
    
    // Handling changes to size of the view–to avoid stretching
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.size = size
        output = createTexture(size: size)
    }
    // All compute shaders and frame logic should go here
    func draw(in view: MTKView, commandBuffer: MTLCommandBuffer) {
        frame += 1
    }
    // Rendering the image to the frame
    func renderToFrame(in view: MTKView, commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(renderPipeline)
        renderEncoder?.setFragmentTexture(output, index: 0)
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder?.endEncoding()
    }
    
    // Do not override this!
    func iterate(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { print("command buffer failed"); return }
        guard let drawable = view.currentDrawable else { print("view has no drawable"); return }
        semaphore.wait()
        commandBuffer.addCompletedHandler { _ in
            self.semaphore.signal()
        }
        
        draw(in: view, commandBuffer: commandBuffer)
        renderToFrame(in: view, commandBuffer: commandBuffer)
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
}

// MARK: Textures
extension Renderer {
    
    var imageThreadCount: MTLSize { MTLSize(width: (Int(size.width) + dispatchSize.width - 1) / dispatchSize.width,
                                   height: (Int(size.height) + dispatchSize.height - 1) / dispatchSize.height,
                                   depth: 1) }
    
    func customDispatchCount(bufferSize: MTLSize, dispatchSize: MTLSize? = nil) -> MTLSize {
        let dispatchSize: MTLSize = {
            if let dispatchSize = dispatchSize {
                return dispatchSize
            } else {
                return self.dispatchSize
            }
        }()
        return MTLSize(width: (bufferSize.width + dispatchSize.width - 1) / dispatchSize.width,
                       height: (bufferSize.height + dispatchSize.height - 1) / dispatchSize.height,
                       depth: 1)
    }
    
    func createTexture(size: CGSize, editable: Bool = false) -> MTLTexture? {
        let renderTargetDescriptor = MTLTextureDescriptor()
        renderTargetDescriptor.pixelFormat = MTLPixelFormat.rgba32Float
        renderTargetDescriptor.textureType = MTLTextureType.type2D
        renderTargetDescriptor.width = Int(size.width)
        renderTargetDescriptor.height = Int(size.height)
        
        #if os(iOS)
        renderTargetDescriptor.storageMode = editable ? .shared : .private // managed is not accessible on iOS
        #else
        renderTargetDescriptor.storageMode = editable ? .managed : .private
        #endif
        
        renderTargetDescriptor.usage = [.shaderRead, .shaderWrite]
        return Renderer.device.makeTexture(descriptor: renderTargetDescriptor)
    }
    
}
// MARK: Functions
extension Renderer {
    
    static var defaultVertexShader = createFunction("copyVertex")
    static var defaultFragmentShader = createFunction("copyFragment")
    static var defaultRenderPipeline: MTLRenderPipelineState {
        createRenderPipeline(vertexFunction: defaultVertexShader, fragmentFunction: defaultFragmentShader)
    }
    static var defaultCopyShader = try! Renderer.device.makeComputePipelineState(function: createFunction("encodeImage")!)
    
    static func createRenderPipeline(vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?) -> MTLRenderPipelineState {
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.sampleCount = 1
        renderDescriptor.vertexFunction = vertexFunction
        renderDescriptor.fragmentFunction = fragmentFunction
        renderDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        return try! device.makeRenderPipelineState(descriptor: renderDescriptor)
    }
    
    static func createFunction(_ name: String) -> MTLFunction? {
        let library = device.makeDefaultLibrary()
        return library?.makeFunction(name: name)
    }
    
    static func createFunctions(_ names: String...) -> [MTLFunction?] {
        var functions = [MTLFunction?]()
        let library = device.makeDefaultLibrary()
        for i in names {
            functions.append(library?.makeFunction(name: i))
        }
        return functions
    }
    
}
