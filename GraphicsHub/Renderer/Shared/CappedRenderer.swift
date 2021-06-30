//
//  CappedRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/29/21.
//

import MetalKit

protocol CappedRenderer: Renderer {
    // Whether the view should render the image at small intervals (maxRenderSize)
    static var rayCapped: Bool { get }
    var computeSize: CGSize { get set }
    var frame: Int { get set }
}

extension CappedRenderer {
    func getCappedGroupSize() -> MTLSize {
        return MTLSize(width: (Int(computeSize.width) + 7)/8 , height: (Int(computeSize.height) + 7)/8, depth: 1)
    }
    func getDirectory(frameIndex: Int) throws -> URL {
        if let url = url {
            return url
        } else {
            let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
            let desktopDirectory = paths[0]
            let docURL = URL(string: desktopDirectory)!
            let dataPath = docURL.appendingPathComponent("\(name)-\(frameIndex)")
            if !FileManager.default.fileExists(atPath: dataPath.path) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
                    return dataPath
                } catch {
                    print(error.localizedDescription)
                    throw error
                }
            }
            print(dataPath)
            // TODO: FIX THIS
            return dataPath
        }
    }
}

class SinglyCappedRenderer: CappedRenderer {
    
    var name: String = "SinglyCapped Renderer"
    
    var recordPipeline: MTLComputePipelineState!
    
    var inputManager: RendererInputManager
    
    var url: URL?
    
    func synchronizeInputs() {
        if inputManager.size() != size {
            drawableSizeDidChange(size: inputManager.size())
        }
        let inputManager = self.inputManager as! CappedInputManager
        let currentComputeSize = inputManager.computeSize()
        if computeSize != currentComputeSize {
            computeSize = currentComputeSize
            computeSizeDidChange(size: currentComputeSize)
        }
        (inputManager.inputs as! [InputShell]).forEach {
            if $0.didChange {
                frame = inputManager.animatorManager.frameRange.0
                intermediateFrame = 0
                return
            }
        }
    }
    
    func computeSizeDidChange(size: CGSize) {}
    
    static var rayCapped: Bool = true
    var computeSize: CGSize = CGSize(width: 512, height: 512)
    var size: CGSize
    
    var device: MTLDevice
    
    var renderSpecificInputs: [NSView]?
    
    var filledRender: Bool {
        return intermediateFrame != 0 && intermediateFrame % (Int(ceil(size.width / computeSize.width)) * Int(ceil(size.height / computeSize.height))) == 0
    }
    var recordable: Bool {
        return filledRender
    }
    internal var image: MTLTexture!
    var outputImage: MTLTexture! {
        image
    }
    
    var resizeable: Bool { false }
    
    var frame: Int = 0
    internal var intermediateFrame: Int = 0
    
    func drawableSizeDidChange(size: CGSize) {
        self.size = size
        self.image = createTexture(size: size)
        self.computeSize = .clamp(value: computeSize, minValue: CGSize(width: 1, height: 1), maxValue: size)
        frame = 0
    }
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        if recordable {
            frame += 1
            intermediateFrame = 0
        } else {
            intermediateFrame += 1
        }
    }
    
    var renderPipelineState: MTLRenderPipelineState?
    
    init(device: MTLDevice, size: CGSize, inputManager: CappedInputManager? = nil) {
        self.size = size
        self.device = device
        if let inputManager = inputManager {
            self.inputManager = inputManager
        } else {
            self.inputManager = CappedInputManager(renderSpecificInputs: [], imageSize: size)
        }
        image = createTexture(size: size)
        
        recordPipeline = try! getRecordPipeline()
    }
    
    required init(device: MTLDevice, size: CGSize) {
        self.size = size
        self.device = device
        self.inputManager = CappedInputManager(renderSpecificInputs: [], imageSize: size)
        image = createTexture(size: size)
        
        recordPipeline = try! getRecordPipeline()
    }
    
    func addAttachments(pipeline: MTLRenderCommandEncoder) {
    }
    
    func setupResources(commandQueue: MTLCommandQueue?) {}
}

class AntialiasingRenderer: SinglyCappedRenderer {
    
    internal var images = [MTLTexture]()
    private var imageCount: Int
    override var outputImage: MTLTexture! {
        images.last!
    }
    private var averagePipeline: MTLComputePipelineState!
    
    var renderPasses = 0
    override var recordable: Bool {
        guard let inputManager = inputManager as? AntialiasingInputManager else { fatalError() }
        return renderPasses >= inputManager.renderPasses && filledRender
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
        if recordable {
            frame += 1
            renderPasses = 0
            intermediateFrame = 0
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

class SimpleRenderer: Renderer {
    var name: String
    
    var device: MTLDevice
    
    var renderSpecificInputs: [NSView]?
    var inputManager: RendererInputManager
    func synchronizeInputs() {
        if inputManager.size() != size {
            drawableSizeDidChange(size: inputManager.size())
        }
    }
    
    var size: CGSize
    var recordable: Bool = true
    var recordPipeline: MTLComputePipelineState!
    
    var outputImage: MTLTexture!
    var resizeable: Bool { false }
    
    var renderPipelineState: MTLRenderPipelineState?
    
    var url: URL?
    var frame: Int = 0
    
    required init(device: MTLDevice, size: CGSize) {
        name = "Simple Renderer"
        self.device = device
        self.size = size
        inputManager = BasicInputManager(imageSize: size)
        drawableSizeDidChange(size: size)
    }
    
    init(device: MTLDevice, size: CGSize, inputManager: RendererInputManager, name: String) {
        self.name = name
        self.device = device
        self.size = size
        self.inputManager = inputManager
    }
    
    func drawableSizeDidChange(size: CGSize) {
        self.size = size
        outputImage = createTexture(size: size)
        frame = 0
    }
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView) { frame += 1 }
    
    func addAttachments(pipeline: MTLRenderCommandEncoder) {}
    
    func setupResources(commandQueue: MTLCommandQueue?) {}
    
    func getDirectory(frameIndex: Int) throws -> URL {
        if let url = url {
            return url
        } else {
            let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
            let desktopDirectory = paths[0]
            let docURL = URL(string: desktopDirectory)!
            let dataPath = docURL.appendingPathComponent("\(name)-\(frameIndex)")
            if !FileManager.default.fileExists(atPath: dataPath.path) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
                    return dataPath
                } catch {
                    print(error.localizedDescription)
                    throw error
                }
            }
            // TODO: Implement Error
//            fatalError()
            return dataPath
        }
    }
}
