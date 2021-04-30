//
//  Tester.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import MetalKit

class TesterBaseRenderer: Renderer {
    
    var recordable: Bool = true
    
    
    var renderPipelineState: MTLRenderPipelineState?
    
    var device: MTLDevice
    var inputView: NSView? = nil
    
    var size: CGSize
    var outputImage: MTLTexture!
    var resizeable: Bool = true
    
    required init(View: RenderingView, size: CGSize) {
        self.device = View.device!
        self.size = size
        do {
            let library = device.makeDefaultLibrary()!
            if let vertexFunction = getDefaultVertexFunction(library: library), let fragmentFunction = library.makeFunction(name: "testerFragment") {
                self.renderPipelineState = try createRenderPipelineState(vertexFunction: vertexFunction, fragmentFunction: fragmentFunction)
            }
        } catch {
            print(error)
        }
        guard let texture = createTexture(size: size) else {
            fatalError("Failed to create texture")
        }
        self.outputImage = texture
    }
    
    required init(device: MTLDevice, size: CGSize) {
        self.device = device
        self.size = size
        
        do {
            let library = device.makeDefaultLibrary()!
            if let vertexFunction = getDefaultVertexFunction(library: library), let fragmentFunction = library.makeFunction(name: "testerFragment") {
                self.renderPipelineState = try createRenderPipelineState(vertexFunction: vertexFunction, fragmentFunction: fragmentFunction)
            }
        } catch {
            print(error)
        }
        guard let texture = createTexture(size: size) else {
            fatalError("Failed to create texture")
        }
        self.outputImage = texture
    }
    
    func drawableSizeDidChange(size: CGSize) {
        self.size = size
        guard let texture = createTexture(size: size) else {
            print("Failed to create texture")
            return
        }
        self.outputImage = texture
    }
    
    func graphicsPipeline(commandBuffer: MTLCommandBuffer, view: MTKView) {}
}
