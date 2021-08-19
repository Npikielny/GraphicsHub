//
//  DataTypes.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/14/21.
//

import SceneKit

struct Ray {
    var origin: SIMD3<Float>
    var direction: SIMD3<Float>
    var energy: SIMD3<Float>
    var result: SIMD3<Float>
}

struct Camera {
    var fov: Float = 30
    var aspectRatio: Float = 1
    var position: SIMD3<Float>
    var rotation: SIMD3<Float>
    
    
    func makeProjectionMatrix() -> float4x4 {
        let  n:Float = 0.3
        let  f:Float = 1000

        let  r = tan(-fov / 180*Float.pi / 2)
        let  l = tan(fov / 180*Float.pi / 2)

        let  t = tan(fov / 180 * Float.pi / 2) * aspectRatio
        let  b = -1 * tan(fov / 180 * Float.pi / 2) * aspectRatio

        let X = 2 * n / (r - l)
        let Y = 2 * n / (t - b)

        let A = (r + l) / (r - l)
        let B = (t + b) / (t - b)
        let C = -1 * (f + n) / (f - n)
        let D = -2 * f * n / (f - n)
        let E: Float = -1

        let column0: SIMD4<Float> = SIMD4(X ,0 ,0 ,0)
        let column1: SIMD4<Float> = SIMD4(0 ,Y ,0 ,0)
        let column2: SIMD4<Float> = SIMD4(A ,B ,C ,E)
        let column3: SIMD4<Float> = SIMD4(0 ,0 ,D ,0)
        var matrix = float4x4(column0, column1, column2, column3)
        let rotationMatrixX = float4x4(simd_quatf(angle: rotation.x / 180 * Float.pi, axis: SIMD3<Float>(1, 0, 0)))
        let rotationMatrixY = float4x4(simd_quatf(angle: rotation.y / 180 * Float.pi, axis: SIMD3<Float>(0, 1, 0)))
        let rotationMatrixZ = float4x4(simd_quatf(angle: rotation.z / 180 * Float.pi, axis: SIMD3<Float>(0, 0, 1)))
        matrix *= rotationMatrixX * rotationMatrixY * rotationMatrixZ
        return matrix.inverse
    }

    func makeModelMatrix() -> float4x4 {
        return float4x4(rows: [SIMD4(1, 0, 0, position.x),
                               SIMD4(0, 1, 0, position.y),
                               SIMD4(0, 0, -1, position.z),
                               SIMD4(0, 0, 0, 1)])
    }

}

struct Material {
    var albedo: SIMD3<Float>
    var specular: SIMD3<Float>
    var n: Float
    var transparency: Float
    var emission: SIMD3<Float>
    enum MaterialType {
        case solid
        case metallic
        case wacky
        case light
        case random
        case randomNormal
        case randomLit
        case solidLit
        case glassy
    }
    static func createMaterial(materialType: Material.MaterialType) -> Material {
        switch materialType {
            case .solidLit:
                return createMaterial(materialType: [.solid, .light].randomElement()!)
            case .randomLit:
                return createMaterial(materialType: [.solid, .metallic, .light].randomElement()!)
            case .random:
                return createMaterial(materialType: [MaterialType.solid, MaterialType.metallic, MaterialType.wacky].randomElement()!)
            case .randomNormal:
                return createMaterial(materialType: [MaterialType.solid, MaterialType.metallic].randomElement()!)
            case .metallic:
                let color = SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
                let metallicness = Float.random(in: 0.99...1)
                return Material(albedo: color * (1 - metallicness), specular: color * metallicness, n: 1, transparency: 0, emission: SIMD3<Float>(repeating: 0))
            case .solid:
                let color = SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
                let metallicness = Float.random(in: 0...0.1)
                return Material(albedo: color * (1 - metallicness), specular: color * metallicness, n: 1, transparency: 0, emission: SIMD3<Float>(repeating: 0))
            case .wacky:
                return Material(albedo: SIMD3<Float>(Float.random(in: 0...1),
                                                     Float.random(in: 0...1),
                                                     Float.random(in: 0...1)),
                                specular: SIMD3<Float>(Float.random(in: 0...1),
                                                       Float.random(in: 0...1),
                                                       Float.random(in: 0...1)),
                                n: 1,
                                transparency: 0,
                                emission: SIMD3<Float>(repeating: 0))
            case .light:
                let color = SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
                return Material(albedo: color, specular: color, n: 0, transparency: 0, emission: color * Float.random(in: 0.1...0.85))
            case .glassy:
                return Material(albedo: SIMD3<Float>(1, 1, 1), specular: SIMD3<Float>(1, 1, 1) * 0.5, n: Float.random(in: 1.3...1.8), transparency: 1, emission: SIMD3<Float>(repeating: 0))
            default:
                return Material(albedo: SIMD3<Float>(1,1,1), specular: SIMD3<Float>(1,1,1), n: 1, transparency: 0, emission: SIMD3<Float>(repeating: 0))
        }
    }
}

struct Object {
    var objectType: Int32
    
    var position: SIMD3<Float>
    var size: SIMD3<Float>
    var rotation: SIMD3<Float>
    var material:  Material
    
    static func sphere(materialType: Material.MaterialType, minPosition: SIMD2<Float>, maxPosition: SIMD2<Float>) -> Object {
        let radius = Float.random(in: 1...10)
        let position = SIMD3<Float>(Float.random(in: minPosition.x...maxPosition.x), radius, Float.random(in: minPosition.y...maxPosition.y))
        return Object(objectType: ObjectType.Sphere.rawValue,
                      position: position,
                      size: SIMD3<Float>(radius, 0, 0),
                      rotation: SIMD3<Float>(0, 0, 0),
                      material: Material.createMaterial(materialType: materialType))
    }
    
    static func newObject(materialType: Material.MaterialType, position: SIMD3<Float>, size: SIMD3<Float>, rotation: SIMD3<Float>, objectType: ObjectType) -> Object {
        switch objectType {
        case .Sphere:
            return sphere(materialType: materialType, position: position, size: size)
        case .Box:
            return box(materialType: materialType, position: position, size: size, rotation: rotation)
        case .Triangle:
            return triangle(materialType: materialType, v0: position, v1: size, v2: rotation)
        }
    }

    static func sphere(material: Material, position: SIMD3<Float>, size: SIMD3<Float>) -> Object {
        return Object(objectType: ObjectType.Sphere.rawValue,
                      position: position,
                      size: SIMD3<Float>(size.x, 0, 0),
                      rotation: SIMD3<Float>(0, 0, 0),
                      material: material)
    }
    
    static func sphere(materialType: Material.MaterialType, position: SIMD3<Float>, size: SIMD3<Float>) -> Object {
        return Object(objectType: ObjectType.Sphere.rawValue,
                      position: position,
                      size: SIMD3<Float>(size.x, 0, 0),
                      rotation: SIMD3<Float>(0, 0, 0),
                      material: Material.createMaterial(materialType: materialType))
    }
    
    static func box(materialType: Material.MaterialType, minPosition: SIMD2<Float>, maxPosition: SIMD2<Float>, rotation: SIMD3<Float>) -> Object {
        let height = Float.random(in: 1...10)
        let position = SIMD3<Float>(Float.random(in: minPosition.x...maxPosition.x), height, Float.random(in: minPosition.y...maxPosition.y))
        return Object(objectType: ObjectType.Box.rawValue,
                      position: position,
                      size: SIMD3<Float>(Float.random(in: 1...10), height, Float.random(in: 1...10)),
                      rotation: rotation,
                      material: Material.createMaterial(materialType: materialType))
    }
    
    static func box(materialType: Material.MaterialType, position: SIMD3<Float>, size: SIMD3<Float>, rotation: SIMD3<Float>) -> Object {
        return box(material: Material.createMaterial(materialType: materialType), position: position, size: size, rotation: rotation)
    }
    static func box(material: Material, position: SIMD3<Float>, size: SIMD3<Float>, rotation: SIMD3<Float>) -> Object {
        return Object(objectType: ObjectType.Box.rawValue,
                      position: position,
                      size: size,
                      rotation: rotation,
                      material: material)
    }
    
    static func triangle(materialType: Material.MaterialType, v0: SIMD3<Float>, v1: SIMD3<Float>, v2: SIMD3<Float>) -> Object {
        return triangle(material: Material.createMaterial(materialType: materialType), v0: v0, v1: v1, v2: v2)
    }
    
    static func triangle(material: Material, v0: SIMD3<Float>, v1: SIMD3<Float>, v2: SIMD3<Float>) -> Object {
        return Object(objectType: ObjectType.Triangle.rawValue,
                      position: v0,
                      size: v1,
                      rotation: v2,
                      material: material)
    }
    
    static func cone(materialType: Material.MaterialType, point: SIMD3<Float>, size: SIMD3<Float>, rotation: SIMD3<Float>) -> Object {
        return cone(material: Material.createMaterial(materialType: materialType),
                    point: point,
                    size: size,
                    rotation: rotation)
    }
    
    static func cone(material: Material, point: SIMD3<Float>, size: SIMD3<Float>, rotation: SIMD3<Float>) -> Object {
        return Object(objectType: 6, position: point, size: size, rotation: rotation, material: material)
    }
    
    enum ObjectType: Int32, Hashable {
        case Sphere
        case Box
        case Triangle
    }
    
    func getType() -> ObjectType? {
        let Types: [ObjectType] = [.Sphere, .Box, .Triangle]
        for Type in Types {
            if objectType == Type.rawValue {
                return Type
            }
        }
        return nil
    }
    
    func getIntersectionFunctionIndex() -> Int {
        return 0
    }
    
    var center: SIMD3<Float> {
        switch getType() {
        case .Triangle:
            return (position + rotation + size) / 3
        default:
            return position
        }
    }
    
    var radius: Float {
        switch getType() {
        case .Sphere:
            return size.x
        case .Box:
            return pow(pow(size.x, 2) + pow(size.y, 2) + pow(size.z, 2), 0.5)
        case .Triangle:
            let center = center
            return max(distance(center, position), max(distance(center, size), distance(center, rotation)))
        case .none:
            fatalError()
        }
//        if objectType == ObjectType.Sphere.rawValue {
//            return size.x
//        } else {
//            return pow(pow(size.x, 2) + pow(size.y, 2) + pow(size.z, 2), 0.5)
//        }
    }
    
    static func intersect(object1: Object, object2: Object) -> Bool {
        return length(object1.center - object2.center) < object1.radius + object2.radius
    }
    
    struct BoundingBox {
        var min: MTLPackedFloat3
        var max: MTLPackedFloat3
    }
    var boundingBoxes: BoundingBox {
        let convert: (SIMD3<Float>) -> MTLPackedFloat3 = { vector in
            var output = MTLPackedFloat3()
            output.x = vector.x
            output.y = vector.y
            output.z = vector.z
            return output
        }
        switch getType() {
        case .Sphere:
            return BoundingBox(min: convert(position - SIMD3(repeating: radius)),
                               max: convert(position + SIMD3(repeating: radius)))
        case .Box:
            return BoundingBox(min: convert(position - size / 2),
                               max: convert(position + size / 2))
        case .Triangle:
            var Min = SIMD3<Float>(repeating: Float.infinity)
            var Max = SIMD3<Float>(repeating: -Float.infinity)
            for vert in [position, size, rotation] {
                Min.x = min(Min.x, vert.x)
                Min.y = min(Min.y, vert.y)
                Min.z = min(Min.z, vert.z)
                
                Max.x = max(Max.x, vert.x)
                Max.y = max(Max.y, vert.y)
                Max.z = max(Max.z, vert.z)
            }
            return BoundingBox(min: convert(Min),
                               max: convert(Max))
        case .none:
            fatalError()
        }
    }
}

struct Scene {
    
}
