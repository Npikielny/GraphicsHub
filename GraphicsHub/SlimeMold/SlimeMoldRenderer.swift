//
//  SlimeMoldRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/8/21.
//

import MetalKit

class SlimeMoldRenderer: Renderer {
    var name: String = "Slime Mold Simulation"
    
    var device: MTLDevice
    
    var renderSpecificInputs: [NSView]?
    
    var inputManager: InputManager
    
    func synchronizeInputs() {
        if inputManager.size() != size {
            drawableSizeDidChange(size: inputManager.size())
        }
    }
    
    var size: CGSize
    
    var recordable: Bool = true
    
    var recordPipeline: MTLComputePipelineState!
    
    var outputImage: MTLTexture!
    
    var resizeable: Bool = false
    
    var computePipeline: MTLComputePipelineState!
    var drawPipeline: MTLComputePipelineState!
    
    var moldBuffer: MTLBuffer!
    
    func drawableSizeDidChange(size: CGSize) {
        self.size = size
        outputImage = createTexture(size: size)
        
    }
    
    func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        
    }
    
    var renderPipelineState: MTLRenderPipelineState?
    
    required init(device: MTLDevice, size: CGSize) {
        self.device = device
        inputManager = SlimeMoldInputManager(imageSize: size)
        self.size = size
        do {
            let functions = createFunctions(names: "slimeMoldCalculate", "slimeMoldDraw")
            computePipeline = try device.makeComputePipelineState(function: functions[0]!)
            drawPipeline = try device.makeComputePipelineState(function: functions[1]!)
        } catch {
            print(error)
            fatalError()
        }
    }
    
    struct Node {
        var position: SIMD2<Float>
        var direction: Float
    }
}

class SlimeMoldInputManager: BasicInputManager {
    
}
