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
}

extension CappedRenderer {
    func getCappedGroupSize() -> MTLSize {
        return MTLSize(width: (Int(maxRenderSize.width) + 7)/8 , height: (Int(maxRenderSize.height) + 7)/8, depth: 1)
    }
}

class SinglyCappedRenderer: CappedRenderer {
    
    static var rayCapped: Bool = true
    var maxRenderSize: CGSize = CGSize(width: 512, height: 512)
    var size: CGSize
    
    var device: MTLDevice
    
    var inputView: [NSView]?
    
    var recordable: Bool {
        return frame % (Int(ceil(size.width / maxRenderSize.width)) * Int(ceil(size.height / maxRenderSize.height))) == 0
    }
    internal var image: MTLTexture!
    var outputImage: MTLTexture! {
        image
    }
    
    var resizeable: Bool { false }
    
    internal var frame: Int = 0
    
    func drawableSizeDidChange(size: CGSize) {
        self.size = size
        self.image = createTexture(size: size)
        frame = 0
    }
    
    func graphicsPipeline(commandBuffer: MTLCommandBuffer, view: MTKView) {}
    
    var renderPipelineState: MTLRenderPipelineState?
    
    required init(device: MTLDevice, size: CGSize) {
        self.size = size
        self.device = device
        self.image = createTexture(size: size)
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
