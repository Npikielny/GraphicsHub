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
    var maxRenderSize: CGSize { get set }
    var frame: Int { get set }
}

extension CGSize {
    static func clamp(value: CGSize, minValue: CGSize, maxValue: CGSize) -> CGSize {
        return Min(size1: maxValue, size2: Max(size1: value, size2: minValue))
    }
    static func Min(size1: CGSize, size2: CGSize) -> CGSize {
        return CGSize(width: min(size1.width, size2.width), height: min(size1.height, size2.height))
    }
    static func Max(size1: CGSize, size2: CGSize) -> CGSize {
        return CGSize(width: max(size1.width, size2.width), height: max(size1.height, size2.height))
    }
}

extension CappedRenderer {
    func getCappedGroupSize() -> MTLSize {
        return MTLSize(width: (Int(maxRenderSize.width) + 7)/8 , height: (Int(maxRenderSize.height) + 7)/8, depth: 1)
    }
}

class SinglyCappedRenderer: CappedRenderer {
    var name: String = "SinglyCappedRenderer"
    
    var recordPipeline: MTLComputePipelineState!
    
    var inputManager: GeneralInputManager!
    
    func synchronizeInputs() {
        if inputManager.size != size {
            drawableSizeDidChange(size: inputManager.size)
        }
        let inputs = inputManager as! CappedInputManager
        setRenderSize(renderSize: inputs.renderSize)
        inputs.syncSize(size: size, renderSize: maxRenderSize)
    }
    
    func setRenderSize(renderSize: CGSize) {
        let clamped: CGSize = .Min(size1: renderSize, size2: size)
        if clamped != maxRenderSize {
            maxRenderSize = clamped
            frame = 0
        }
        if let renderSpecificInputs = renderSpecificInputs, renderSpecificInputs.contains(where: { ($0 as! Input).didChange }) {
            frame = 0
        }
//        if maxRenderSize != renderSize {
//            let clamped: CGSize = .clamp(value: renderSize, minValue: CGSize(width: 1, height: 1), maxValue: size)
//            if clamped != maxRenderSize {
//                maxRenderSize = clamped
//                frame = 0
//            }
//        }
    }
    
    static var rayCapped: Bool = true
    var maxRenderSize: CGSize = CGSize(width: 512, height: 512)
    var size: CGSize
    
    var device: MTLDevice
    
    var renderSpecificInputs: [NSView]?
    
    var recordable: Bool {
        return frame % (Int(ceil(size.width / maxRenderSize.width)) * Int(ceil(size.height / maxRenderSize.height))) == 0
    }
    internal var image: MTLTexture!
    var outputImage: MTLTexture! {
        image
    }
    
    var resizeable: Bool { false }
    
    var frame: Int = 0
    
    func drawableSizeDidChange(size: CGSize) {
        self.size = size
        self.image = createTexture(size: size)
        self.maxRenderSize = .clamp(value: maxRenderSize, minValue: CGSize(width: 1, height: 1), maxValue: size)
        frame = 0
    }
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {}
    
    var renderPipelineState: MTLRenderPipelineState?
    
    required init(device: MTLDevice, size: CGSize) {
        self.size = size
        self.device = device
        image = createTexture(size: size)
        
        recordPipeline = try! getRecordPipeline()
    }
}

class DoublyCappedenderer: SinglyCappedRenderer {
    internal var images = [MTLTexture]()
    override var outputImage: MTLTexture! {
        images.last!
    }
    override func drawableSizeDidChange(size: CGSize) {
        self.size = size
        for i in 0..<self.images.count {
            self.images[i] = createTexture(size: size)!
        }
        frame = 0
    }
}
