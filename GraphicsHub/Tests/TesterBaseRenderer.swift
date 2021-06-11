//
//  Tester.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import MetalKit

class TesterBaseRenderer: SimpleRenderer {
    
    var url: URL?
    
    var name: String = "TesterBaseRenderer"
    
    var recordPipeline: MTLComputePipelineState!
    
    var inputManager: RendererInputManager
    func synchronizeInputs() {
        if inputManager.size() != size {
            drawableSizeDidChange(size: inputManager.size())
        }
        updateAllInputs()
    }
    var recordable: Bool = true
    
    var renderPipelineState: MTLRenderPipelineState?
    
    var device: MTLDevice
    var renderSpecificInputs: [NSView]? = nil
    
    var size: CGSize
    var outputImage: MTLTexture!
    var resizeable: Bool = true
    
    required init(device: MTLDevice, size: CGSize) {
        self.inputManager = BasicInputManager(imageSize: size)
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
    
    var frameStable: Bool { true }
    var frame: Int = 0
    
    func drawableSizeDidChange(size: CGSize) {
        self.size = size
        guard let texture = createTexture(size: size) else {
            print("Failed to create texture")
            return
        }
        self.outputImage = texture
        frame = 0
    }
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        frame += 1
    }
}
