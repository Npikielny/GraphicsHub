//
//  RayTraceRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/25/21.
//

import MetalKit

class RayRenderer: AntialiasingRenderer {
    
    var camera: Camera
    
    var objects: [Object]
    var objectBuffer: MTLBuffer!
    var lightDirection: SIMD4<Float>
    var skyIntensity: Float = 1
    
    override func synchronizeInputs() {
        super.synchronizeInputs()
        guard let inputManager = inputManager as? RayInputManager else { return }
        camera.fov = inputManager.fov
        camera.aspectRatio = inputManager.aspectRatio
        camera.position = inputManager.position
        camera.rotation = inputManager.rotation
        lightDirection = inputManager.light
        skyIntensity = inputManager.skyIntensity
    }
    
    required init(device: MTLDevice, size: CGSize) {
        objects = SceneManager.generate(objectCount: 10,
                                        objectTypes: [.Sphere, .Box],
                                        generationType: .procedural,
                                        positionType: .radial,
                                        collisionType: [.distinct],
                                        objectSizeRange: (SIMD3<Float>(repeating: 0.1), SIMD3<Float>(repeating: 2)),
                                        objectPositionRange: (SIMD3<Float>(1, 0, 0), SIMD3<Float>(10, 2 * Float.pi, 10)),
                                        materialType: .random)
        objectBuffer = device.makeBuffer(bytes: objects, length: MemoryLayout<Object>.stride * objects.count, options: .storageModeManaged)
        lightDirection = SIMD4<Float>(0.1, -0.1, 0.1, 1)
        camera = Camera(position: SIMD3<Float>(0,1,0), rotation: SIMD3<Float>(0, 0, 0))
        super.init(device: device, size: size, inputManager: nil, imageCount: 2)
    }
    
    init(device: MTLDevice,
         size: CGSize,
         camera: Camera? = nil,
         objects: [Object]? = nil,
         lightDirection: SIMD4<Float> = SIMD4<Float>(0.1, -0.1, 0.1, 1),
         inputManager: CappedInputManager,
         imageCount: Int) {
        
        self.objects = objects ?? []
        self.lightDirection = lightDirection
        self.camera = camera ?? Camera(position: SIMD3<Float>(0, 1, 0), rotation: SIMD3<Float>(0, 0, 0))
        
        objectBuffer = device.makeBuffer(length: MemoryLayout<Object>.stride * max((objects?.count ?? 0) * 2, 10), options: .storageModeManaged)
        
        super.init(device: device, size: size, inputManager: inputManager, imageCount: imageCount)
        let objectsSize = MemoryLayout<Object>.stride * self.objects.count
        memcpy(objectBuffer.contents(), self.objects, objectsSize)
        objectBuffer.didModifyRange(0..<objectsSize)
    }
    
    func loadTexture(name: String) throws -> MTLTexture {
        let textureLoaderOption = [
                    MTKTextureLoader.Option.allocateMipmaps: NSNumber(value: false),
                    MTKTextureLoader.Option.SRGB: NSNumber(value: false)
                ]
        // TODO: Add file importing
//        let url = URL(fileURLWithPath: "---/RayTraceComprehensive/RayTraceMPSSimple/Assets.xcassets/cape_hill_4k.imageset/cape_hill_4k copy.jpg")
//        let texture = try! textureLoader.newTexture(URL: url, options: textureLoaderOption)
        let textureLoader = MTKTextureLoader(device: device)
        let image = NSImage(named: name)!
        var size = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let texture = try textureLoader.newTexture(cgImage: image.cgImage(forProposedRect: &size, context: nil, hints: nil)!,
                                                    options: textureLoaderOption)
        return texture
    }
    
}

class RayInputManager: AntialiasingInputManager {
    
    var fov: Float { Float((getInput(0) as! SliderInput).output)}
    var aspectRatio: Float { Float((getInput(1) as! SliderInput).output)}
    
    var position: SIMD3<Float> {
        get {
            SIMD3<Float>(
                Float((getInput(2) as! SliderInput).output),
                Float((getInput(3) as! SliderInput).output),
                Float((getInput(4) as! SliderInput).output))
        }
        set {
            (getInput(2) as! SliderInput).setValue(value: Double(newValue.x))
            (getInput(3) as! SliderInput).setValue(value: Double(newValue.y))
            (getInput(4) as! SliderInput).setValue(value: Double(newValue.z))
        }
    }
    
    var rotation: SIMD3<Float> {
        get {
            SIMD3<Float>(
                Float((getInput(5) as! SliderInput).output),
                Float((getInput(6) as! SliderInput).output),
                Float((getInput(7) as! SliderInput).output))
        }
        set {
                (getInput(5) as! SliderInput).setValue(value: Double(newValue.x))
                (getInput(6) as! SliderInput).setValue(value: Double(newValue.y))
                (getInput(7) as! SliderInput).setValue(value: Double(newValue.z))
        }
    }
    
    var light: SIMD4<Float> {
        SIMD4<Float>(
            Float((getInput(8) as! SliderInput).output),
            Float((getInput(9) as! SliderInput).output),
            Float((getInput(10) as! SliderInput).output),
            Float((getInput(11) as! SliderInput).output))
    }
    
    var skyIntensity: Float {
        Float((getInput(12) as! SliderInput).output)
    }
    
    convenience init(size: CGSize) {
        self.init(renderSpecificInputs: [], imageSize: size)
    }
    
    override init(renderSpecificInputs: [NSView], imageSize: CGSize?) {
        let fov = SliderInput(name: "FOV", minValue: 1, currentValue: 45, maxValue: 180)
        let aspectRatio = SliderInput(name: "Aspect Ratio", minValue: 0.1, currentValue: 1, maxValue: 10)
        
        let cameraX = SliderInput(name: "Camera X", minValue: -200, currentValue: 0, maxValue: 200)
        let cameraY = SliderInput(name: "Camera Y", minValue: -200, currentValue: 0, maxValue: 200)
        let cameraZ = SliderInput(name: "Camera Z", minValue: -200, currentValue: 0, maxValue: 200)
        
        let rotationX = SliderInput(name: "Rotation X", minValue: -360, currentValue: 0, maxValue: 360)
        let rotationY = SliderInput(name: "Rotation Y", minValue: -360, currentValue: 0, maxValue: 360)
        let rotationZ = SliderInput(name: "Rotation Z", minValue: -360, currentValue: 0, maxValue: 360)
        
        let lightX = SliderInput(name: "Light X", minValue: -1, currentValue: 0.1, maxValue: 1)
        let lightY = SliderInput(name: "Light Y", minValue: -1, currentValue: -0.1, maxValue: 1)
        let lightZ = SliderInput(name: "Light Z", minValue: -1, currentValue: 0.1, maxValue: 1)
        let lightIntensity = SliderInput(name: "Light Intensity", minValue: 0, currentValue: 1, maxValue: 2)
        
        let skyIntensity = SliderInput(name: "Sky Intensity", minValue: 0, currentValue: 1, maxValue: 1)
        
        super.init(renderSpecificInputs: [
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
            
            skyIntensity
        ] + renderSpecificInputs, imageSize: imageSize)
    }
    
    override func mouseDragged(event: NSEvent) {
        position += SIMD3(Float(event.deltaX),0,Float(event.deltaY))
    }
    
    override func rightMouseDragged(event: NSEvent) {
        if rotation.y - Float(event.deltaX) < -360 {
            rotation.y += 360 * 2 - Float(event.deltaX)
        } else if rotation.y - Float(event.deltaX) > 360 {
            rotation.y += -360 * 2 - Float(event.deltaX)
        } else {
            rotation.y -= Float(event.deltaX)
        }
        
        if rotation.x + Float(event.deltaY) < -360 {
            rotation.x += 360 * 2 + Float(event.deltaY)
        } else if rotation.x + Float(event.deltaY) > 360 {
            rotation.x += -360 * 2 + Float(event.deltaY)
        } else {
            rotation.x += Float(event.deltaY)
        }
    }
    
    override func flagsChanged(event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            position += SIMD3(0,1,0)
        }
        if event.modifierFlags.contains(.shift) {
            position -= SIMD3(0,1,0)
        }
    }
}

extension RayRenderer {
    
    struct Ray {
        var origin: SIMD3<Float>
        var direction: SIMD3<Float>
        var energy: SIMD3<Float>
        var result: SIMD3<Float>
    }
    
}

