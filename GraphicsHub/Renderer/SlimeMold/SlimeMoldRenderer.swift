//
//  SlimeMoldRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/8/21.
//

import MetalKit

class SlimeMoldRenderer: SimpleRenderer {
    
    var computePipeline: MTLComputePipelineState!
    var drawPipeline: MTLComputePipelineState!
    
    var moldBuffer: MTLBuffer!
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: SlimeMoldInputManager(imageSize: size), name: "Slime Mold Simulation")
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
