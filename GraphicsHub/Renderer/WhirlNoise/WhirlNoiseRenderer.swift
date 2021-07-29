//
//  WhirlNoiseRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/27/21.
//

import MetalKit

class WhirlNoiseRenderer: Renderer {
    
    var whirlNoise: MTLComputePipelineState!
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: WhirlNoiseInputManager(imageSize: size), name: "Whirl Noise")
        let functions = createFunctions(names: "whirlNoiseRendering")
        whirlNoise = try! device.makeComputePipelineState(function: functions[0]!)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        guard let inputManager = inputManager as? WhirlNoiseInputManager else { super.draw(commandBuffer: commandBuffer, view: view); return }
        let noiseEncoder = commandBuffer.makeComputeCommandEncoder()
        noiseEncoder?.setComputePipelineState(whirlNoise)
        noiseEncoder?.setBytes([inputManager.chunkSize], length: MemoryLayout<Int32>.stride, index: 0)
        noiseEncoder?.setBytes([inputManager.seed], length: MemoryLayout<Int32>.stride, index: 1)
        noiseEncoder?.setBytes([inputManager.z], length: MemoryLayout<Float>.stride, index: 2)
        noiseEncoder?.setBytes([inputManager.drawPoints], length: MemoryLayout<Bool>.stride, index: 3)
        noiseEncoder?.setBytes([inputManager.lightingX], length: MemoryLayout<Float>.stride, index: 4)
        noiseEncoder?.setBytes([inputManager.lightingY], length: MemoryLayout<Float>.stride, index: 5)
        noiseEncoder?.setBytes([inputManager.lightingZ], length: MemoryLayout<Float>.stride, index: 6)
        noiseEncoder?.setBytes([inputManager.lightingIntensity], length: MemoryLayout<Float>.stride, index: 7)
        noiseEncoder?.setBytes([inputManager.normals], length: MemoryLayout<Bool>.stride, index: 8)
        noiseEncoder?.setBytes([inputManager.smooth], length: MemoryLayout<Bool>.stride, index: 9)
        noiseEncoder?.setBytes([inputManager.blendingStrength], length: MemoryLayout<Float>.stride, index: 10)
        noiseEncoder?.setBytes([inputManager.scaling], length: MemoryLayout<Float>.stride, index: 11)
        noiseEncoder?.setBytes([inputManager.density], length: MemoryLayout<Float>.stride, index: 12)
        noiseEncoder?.setTexture(outputImage, index: 0)
        noiseEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        noiseEncoder?.endEncoding()
        
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
}

class WhirlNoiseInputManager: BasicInputManager {
    
    var chunkSize: Int32 { Int32((getInput(0) as! SliderInput).output) }
    var seed: Int32 { Int32((getInput(1) as! SliderInput).output) }
    var z: Float { Float((getInput(2) as! SliderInput).output) }
    
    var drawPoints: Bool { (getInput(3) as! StateInput).output }
    var lightingX: Float { Float((getInput(4) as! SliderInput).output) }
    var lightingY: Float { Float((getInput(5) as! SliderInput).output) }
    var lightingZ: Float { Float((getInput(6) as! SliderInput).output) }
    var lightingIntensity: Float { Float((getInput(7) as! SliderInput).output) }
    
    var normals: Bool { (getInput(8) as! StateInput).output }
    
    var smooth: Bool { (getInput(9) as! StateInput).output }
    var blendingStrength: Float { Float((getInput(10) as! SliderInput).output) }
    
    var scaling: Float { Float((getInput(11) as! SliderInput).output) }
    var density: Float { Float((getInput(12) as! SliderInput).output) }
    
    override init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        let chunkSize = SliderInput(name: "ChunkSize", minValue: 3, currentValue: 10, maxValue: 100)
        let seed = SliderInput(name: "Seed", minValue: 0, currentValue: 761579, maxValue: 999999)
        let z = SliderInput(name: "Z", minValue: -100, currentValue: 0, maxValue: 100)
        let drawPoints = StateInput(name: "Points")
        drawPoints.output = true
        let lightingX = SliderInput(name: "Lighting X", minValue: -1, currentValue: -0.1, maxValue: 1)
        let lightingY = SliderInput(name: "Lighting Y", minValue: -1, currentValue: -0.1, maxValue: 1)
        let lightingZ = SliderInput(name: "Lighting Z", minValue: -1, currentValue: -0.1, maxValue: 1)
        let lightingIntensity = SliderInput(name: "Intensity", minValue: 0, currentValue: 1, maxValue: 1)
        let normals = StateInput(name: "Show Normals")
        let smooth = StateInput(name: "Smooth")
        let blendingStrength = SliderInput(name: "Blending", minValue: 0, currentValue: 0.5, maxValue: 1)
        let scaling = SliderInput(name: "Scaling", minValue: -1, currentValue: 0, maxValue: 1)
        let density = SliderInput(name: "Density", minValue: 0.5, currentValue: 1, maxValue: 1)
        super.init(renderSpecificInputs: [chunkSize, seed, z, drawPoints, lightingX, lightingY, lightingZ, lightingIntensity, normals, smooth, blendingStrength, scaling, density] + renderSpecificInputs, imageSize: imageSize)
    }
}
