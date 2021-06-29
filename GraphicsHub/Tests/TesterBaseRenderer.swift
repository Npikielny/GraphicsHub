//
//  Tester.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

import MetalKit

class TesterBaseRenderer: SimpleRenderer {
    
    override func synchronizeInputs() {
        if inputManager.size() != size {
            drawableSizeDidChange(size: inputManager.size())
        }
        updateAllInputs()
    }
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: BasicInputManager(imageSize: size), name: "Test Base Renderer")
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
    
    override func addAttachments(pipeline: MTLRenderCommandEncoder) {
        pipeline.setFragmentTexture(outputImage, index: 0)
    }
}
