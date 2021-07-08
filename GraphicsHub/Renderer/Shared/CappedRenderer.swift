//
//  CappedRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/29/21.
//

import MetalKit

class SinglyCappedRenderer: Renderer {
    
    var computeSize: CGSize = CGSize(width: 512, height: 512)
    
    var filledRender: Bool {
        return intermediateFrame != 0 && intermediateFrame % (Int(ceil(size.width / computeSize.width)) * Int(ceil(size.height / computeSize.height))) == 0
    }
    override var recordable: Bool {
        return frame % inputManager.framesPerFrame == 0 && filledRender
    }
    
    override var resizeable: Bool { false }
    
    var intermediateFrame: Int {
        get {
            let inputManager = inputManager as! CappedInputManager
            return inputManager.intermediateFrame
        }
        set {
            let inputManager = inputManager as! CappedInputManager
            inputManager.intermediateFrame = newValue
        }
    }
    
    init(device: MTLDevice, size: CGSize, inputManager: CappedInputManager? = nil, name: String = "SinglyCapped Renderer") {
        super.init(device: device, size: size, inputManager: inputManager ?? CappedInputManager(renderSpecificInputs: [], imageSize: size), name: name)
    }
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: CappedInputManager(renderSpecificInputs: [], imageSize: size), name: "SinglyCapped Renderer")
        recordPipeline = try! getRecordPipeline()
    }
    
    override func synchronizeInputs() {
        let inputManager = self.inputManager as! CappedInputManager
        let currentComputeSize = inputManager.computeSize()
        if computeSize != currentComputeSize {
            computeSize = currentComputeSize
            computeSizeDidChange(size: currentComputeSize)
        }
        (inputManager.inputs as! [InputShell]).forEach {
            if $0.didChange {
                resetRender()
                return
            }
        }
        super.synchronizeInputs()
    }
    
    func resetRender() {
        frame = inputManager.animatorManager.frameDomain.0
        intermediateFrame = 0
    }
    
    func computeSizeDidChange(size: CGSize) {}
    
    func getCappedGroupSize() -> MTLSize {
        return MTLSize(width: Int(computeSize.width + 7) / 8,
                       height: Int(computeSize.height + 7) / 8,
                       depth: 1)
    }
    
    override func drawableSizeDidChange(size: CGSize) {
        self.size = size
        self.image = createTexture(size: size)
        self.computeSize = .clamp(value: computeSize, minValue: CGSize(width: 1, height: 1), maxValue: size)
        inputManager.frame = 0
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        if recordable {
            if !inputManager.paused {
                inputManager.frame += 1
                intermediateFrame = 0
            }
        } else {
            intermediateFrame += 1
        }
    }
}

class AntialiasingRenderer: SinglyCappedRenderer {
    
    internal var images = [MTLTexture]()
    private var imageCount: Int
    override var outputImage: MTLTexture {
        images.last!
    }
    private var averagePipeline: MTLComputePipelineState!
    
    var renderPasses: Int {
        get { let inputManager = inputManager as! AntialiasingRenderer; return inputManager.renderPasses }
        set { let inputManager = inputManager as! AntialiasingRenderer; inputManager.renderPasses = newValue }
    }
    var finalizedImage: Bool {
        guard let inputManager = inputManager as? AntialiasingInputManager else { fatalError() }
        return renderPasses >= inputManager.renderPassesPerFrame && filledRender
    }
    
    override var recordable: Bool {
        return frame % inputManager.framesPerFrame == 0 && finalizedImage
    }
    
    override func resetRender() {
        super.resetRender()
        renderPasses = 0
    }
    
    init(device: MTLDevice, size: CGSize, inputManager: CappedInputManager? = nil, imageCount: Int) {
        self.imageCount = imageCount
        super.init(device: device, size: size, inputManager: inputManager)
        name = "Antialiasing Renderer"
        let functions = createFunctions(names: "averageImages")
        if let averageFunction = functions[0] {
            do {
                averagePipeline = try device.makeComputePipelineState(function: averageFunction)
            } catch {
                print(error)
                fatalError()
            }
        }
        do {
            let library = device.makeDefaultLibrary()!
            if let vertexFunction = getDefaultVertexFunction(library: library), let fragmentFunction = library.makeFunction(name: "cappedCopyFragment") {
                self.renderPipelineState = try createRenderPipelineState(vertexFunction: vertexFunction, fragmentFunction: fragmentFunction)
            }
        } catch {
            print(error)
        }
        drawableSizeDidChange(size: size)
    }
    
    required init(device: MTLDevice, size: CGSize) {
        fatalError("init(device:size:) has not been implemented")
    }
    
    override func drawableSizeDidChange(size: CGSize) {
        self.size = size
        for i in 0..<imageCount {
            if images.count - 1 < i {
                images.append(createTexture(size: size)!)
            } else {
                images[i] = createTexture(size: size)!
            }
        }
        frame = 0
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        // TODO: Only works for imageCount = 2
        if renderPasses > 0 && filledRender {
            let averageEncoder = commandBuffer.makeComputeCommandEncoder()
            averageEncoder?.setComputePipelineState(averagePipeline)
            averageEncoder?.setBytes([Int32(renderPasses)], length: MemoryLayout<Int32>.stride, index: 0)
            averageEncoder?.setTexture(images[0], index: 0)
            averageEncoder?.setTexture(images[1], index: 1)
            averageEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
            averageEncoder?.endEncoding()
            images.swapAt(0, 1)
        }
        if finalizedImage {
            if !inputManager.paused {
                frame += 1
                renderPasses = 0
                intermediateFrame = 0
            }
        }
        if filledRender {
            intermediateFrame = 0
            renderPasses += 1
        } else {
            intermediateFrame += 1
        }
    }
    
    override func addAttachments(pipeline: MTLRenderCommandEncoder) {
        pipeline.setFragmentTexture(images[0], index: 0)
        pipeline.setFragmentTexture(images[1], index: 1)
    }
}
