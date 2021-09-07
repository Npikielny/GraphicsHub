//
//  PerlineNoiseRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/25/21.
//

import MetalKit

class PerlinNoiseRenderer: Renderer {
    
    var perlinPipeline: MTLComputePipelineState!
    
    override var resizeable: Bool { false } 
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: PerlinInputManager(imageSize: size), name: "Perlin Noise Renderer")
        let function = createFunctions("perlinRenderer")
        perlinPipeline = try! device.makeComputePipelineState(function: function!)
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        guard let inputManager = inputManager as? PerlinInputManager else { super.draw(commandBuffer: commandBuffer, view: view); return }
        let perlinEncoder = commandBuffer.makeComputeCommandEncoder()
        perlinEncoder?.setComputePipelineState(perlinPipeline)
        perlinEncoder?.setTexture(outputImage, index: 0)
        
        perlinEncoder?.setBytes([inputManager.octaves], length: MemoryLayout<Int32>.stride, index: 0)
        perlinEncoder?.setBytes([inputManager.noise], length: MemoryLayout<SIMD2<Int32>>.stride, index: 1)
        perlinEncoder?.setBytes([inputManager.noiseSeed], length: MemoryLayout<Int32>.stride, index: 2)
        perlinEncoder?.setBytes([inputManager.seed], length: MemoryLayout<Int32>.stride, index: 3)
        perlinEncoder?.setBytes([inputManager.p], length: MemoryLayout<Float>.stride, index: 4)
        perlinEncoder?.setBytes([inputManager.zoom], length: MemoryLayout<Float>.stride, index: 5)
        perlinEncoder?.setBytes([inputManager.v], length: MemoryLayout<SIMD4<Float>>.stride, index:6)
        
        perlinEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        perlinEncoder?.endEncoding()
        
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
}

class PerlinInputManager: BasicInputManager {
    
    var octaves: Int32 { get { Int32((getInput(0) as! SliderInput).output) } }
    var noise: SIMD2<Int32> { get { (getInput(1) as! SizeInput).output.toVector() } }
    var noiseSeed: Int32 { get { Int32((getInput(2) as! SliderInput).output) } }
    var seed: Int32 { get { Int32((getInput(3) as! SliderInput).output) } }
    var p: Float { get { Float((getInput(4) as! SliderInput).output) } }
    var zoom: Float { get { Float((getInput(5) as! SliderInput).output) } }
    var v: SIMD4<Float> { get { SIMD4<Float>(
        Float((getInput(6) as! SliderInput).output),
        Float((getInput(7) as! SliderInput).output),
        Float((getInput(8) as! SliderInput).output),
        Float((getInput(9) as! SliderInput).output)
    ) } }
    override init(renderSpecificInputs: [NSView] = [], imageSize: CGSize?) {
        let octaves = SliderInput(name: "octaves", minValue: 0, currentValue: 0, maxValue: 12, tickMarks: 13)
        let noise = SizeInput(name: "Noise Offset", prefix: nil, size: CGSize(width: 1619, height: 31337), maxSize: CGSize(width: 40000, height: 40000))
        let noiseSeed = SliderInput(name: "noiseSeed", minValue: 0, currentValue: 1013, maxValue: 10000)
        let seed = SliderInput(name: "seed", minValue: 0, currentValue: 1, maxValue: 10000)
        let p = SliderInput(name: "p", minValue: 0, currentValue: 0.5, maxValue: 1)
        let zoom = SliderInput(name: "zoom", minValue: 0, currentValue: 12, maxValue: 100)
        let v1 = SliderInput(name: "v1", minValue: 0, currentValue: 0.5, maxValue: 1)
        let v2 = SliderInput(name: "v2", minValue: 0, currentValue: 0.5, maxValue: 1)
        let v3 = SliderInput(name: "v3", minValue: 0, currentValue: 0.5, maxValue: 1)
        let v4 = SliderInput(name: "v4", minValue: 0, currentValue: 0.5, maxValue: 1)
        super.init(renderSpecificInputs: [octaves, noise, noiseSeed, seed, p, zoom, v1, v2, v3, v4] + renderSpecificInputs, imageSize: imageSize)
    }
    
}


