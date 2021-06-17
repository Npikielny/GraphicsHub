//
//  VanillaRayTraceRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/16/21.
//

import MetalKit

class VanillaRayTraceRenderer: AntialiasingRenderer {
    
    var camera = Camera(position: SIMD3<Float>(0, 1, 0), rotation: SIMD3<Float>(0, 0, 0))
    
    var spheres: [Sphere] = {
        var spheres = [Sphere]()
        for i in 0...Int.random(in: 5...10) {
            let radius = Float.random(in: 1...10)
            spheres.append(Sphere(position: SIMD4<Float>(Float.random(in: -25...25),radius,Float.random(in: 10...25),radius),
                                  material: Material(albedo: SIMD3<Float>(Float.random(in: 0...1),Float.random(in: 0...1),Float.random(in: 0...1)),
                                                     specular: SIMD3<Float>(Float.random(in: 0...1),Float.random(in: 0...1),Float.random(in: 0...1)),
                                                     n: 1,
                                                     transparency: 0)))
        }
        return spheres
    }()
    var sphereBuffer: MTLBuffer!
    var lightDirection = SIMD4<Float>(0.1, 0.1, 0.1, 1)
    var skyTexture: MTLTexture!
    var skySize: SIMD2<Int32>!
        
    var rayPipeline: MTLComputePipelineState!
    
    override func synchronizeInputs() {
        super.synchronizeInputs()
        guard let inputManager = inputManager as? VanillaRayInputManager else { return }
        camera.fov = inputManager.fov
        camera.aspectRatio = inputManager.aspectRatio
        camera.position = inputManager.position
        camera.rotation = inputManager.rotation
        lightDirection = inputManager.light
    }
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: VanillaRayInputManager(size: size), imageCount: 2)
        name = "Vanilla Ray Trace Renderer"
        sphereBuffer = device.makeBuffer(bytes: spheres, length: MemoryLayout<Sphere>.stride * spheres.count, options: .storageModeManaged)
        let functions = createFunctions(names: "processRays")
        if let rayFunction = functions[0] {
            do {
                rayPipeline = try device.makeComputePipelineState(function: rayFunction)
            } catch {
                print(error)
                fatalError()
            }
        }
        setupSky()
    }
    
    override func draw(commandBuffer: MTLCommandBuffer, view: MTKView) {
        
        let rayEncoder = commandBuffer.makeComputeCommandEncoder()
        rayEncoder?.setComputePipelineState(rayPipeline)
        
        rayEncoder?.setBuffer(sphereBuffer, offset: 0, index: 0)
        rayEncoder?.setBytes([Int32(spheres.count)], length: MemoryLayout<Int32>.stride, index: 1)
        rayEncoder?.setBytes([camera.makeModelMatrix(), camera.makeProjectionMatrix()], length: MemoryLayout<float4x4>.stride * 2, index: 2)
        rayEncoder?.setBytes([SIMD2<Int32>(Int32(size.width), Int32(size.height))], length: MemoryLayout<SIMD2<Int32>>.stride, index: 3)
        rayEncoder?.setBytes([SIMD2<Int32>(Int32(maxRenderSize.width),Int32(maxRenderSize.height))], length: MemoryLayout<SIMD2<Int32>>.stride, index: 4)
        rayEncoder?.setBytes([skySize], length: MemoryLayout<SIMD2<Int32>>.stride, index: 5)
        rayEncoder?.setBytes([lightDirection], length: MemoryLayout<SIMD4<Float>>.stride, index: 6)
        rayEncoder?.setBytes([SIMD2<Float>(Float.random(in: -0.5...0.5),Float.random(in: -0.5...0.5))], length: MemoryLayout<SIMD2<Float>>.stride, index: 7)
        rayEncoder?.setBytes([Int32(intermediateFrame)], length: MemoryLayout<Int32>.stride, index: 8)
        rayEncoder?.setTexture(skyTexture, index: 0)
        rayEncoder?.setTexture(images[0], index: 1)
        
        rayEncoder?.dispatchThreadgroups(getCappedGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        rayEncoder?.endEncoding()
        
        super.draw(commandBuffer: commandBuffer, view: view)
    }
    
    func setupSky() {
        let textureLoaderOption = [
                    MTKTextureLoader.Option.allocateMipmaps: NSNumber(value: false),
                    MTKTextureLoader.Option.SRGB: NSNumber(value: false)
                ]
        // TODO: Add file importing
//        let url = URL(fileURLWithPath: "---/RayTraceComprehensive/RayTraceMPSSimple/Assets.xcassets/cape_hill_4k.imageset/cape_hill_4k copy.jpg")
//        let texture = try! textureLoader.newTexture(URL: url, options: textureLoaderOption)
        let textureLoader = MTKTextureLoader(device: device)
        let image = NSImage(named: "cape_hill_4k")!
        var size = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let texture = try! textureLoader.newTexture(cgImage: image.cgImage(forProposedRect: &size, context: nil, hints: nil)!,
                                                    options: textureLoaderOption)
        self.skyTexture = texture
        skySize = SIMD2(Int32(texture.width),Int32(texture.height))
    }
    
}

class VanillaRayInputManager: AntialiasingInputManager {
    var fov: Float { Float((getInput(0) as! SliderInput).output)}
    var aspectRatio: Float { Float((getInput(1) as! SliderInput).output)}
    
    var position: SIMD3<Float> {
        SIMD3<Float>(
            Float((getInput(2) as! SliderInput).output),
            Float((getInput(3) as! SliderInput).output),
            Float((getInput(4) as! SliderInput).output))
    }
    
    var rotation: SIMD3<Float> {
        SIMD3<Float>(
            Float((getInput(5) as! SliderInput).output),
            Float((getInput(6) as! SliderInput).output),
            Float((getInput(7) as! SliderInput).output))
    }
    
    var light: SIMD4<Float> {
        SIMD4<Float>(
            Float((getInput(8) as! SliderInput).output),
            Float((getInput(9) as! SliderInput).output),
            Float((getInput(10) as! SliderInput).output),
            Float((getInput(11) as! SliderInput).output))
    }
    
    convenience init(size: CGSize) {
        let fov = SliderInput(name: "FOV", minValue: 1, currentValue: 45, maxValue: 180)
        let aspectRatio = SliderInput(name: "Aspect Ratio", minValue: 0.1, currentValue: 1, maxValue: 10)
        
        let cameraX = SliderInput(name: "Camera X", minValue: -50, currentValue: 0, maxValue: 50)
        let cameraY = SliderInput(name: "Camera Y", minValue: -50, currentValue: 0, maxValue: 50)
        let cameraZ = SliderInput(name: "Camera Z", minValue: -50, currentValue: 0, maxValue: 50)
        
        let rotationX = SliderInput(name: "Rotation X", minValue: -180, currentValue: 0, maxValue: 180)
        let rotationY = SliderInput(name: "Rotation Y", minValue: -180, currentValue: 0, maxValue: 180)
        let rotationZ = SliderInput(name: "Rotation Z", minValue: -180, currentValue: 0, maxValue: 180)
        
        let lightX = SliderInput(name: "Light X", minValue: -1, currentValue: 0.1, maxValue: 1)
        let lightY = SliderInput(name: "Light Y", minValue: -1, currentValue: 0.1, maxValue: 1)
        let lightZ = SliderInput(name: "Light Z", minValue: -1, currentValue: 0.1, maxValue: 1)
        let lightIntensity = SliderInput(name: "Light Intensity", minValue: 0, currentValue: 1, maxValue: 2)
        
        self.init(renderSpecificInputs: [
            fov,
            aspectRatio,
            
            cameraX,
            cameraY,
            cameraZ,
            
            rotationX,
            rotationY,
            rotationZ,
            
            lightX,
            lightY,
            lightZ,
            lightIntensity,
        ], imageSize: size)
    }
}
