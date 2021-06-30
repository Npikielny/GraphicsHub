//
//  DataTypes.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/14/21.
//

import SceneKit

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
    enum MaterialType {
        case solid
        case metallic
        case wacky
        case random
        case randomNormal
    }
    static func createMaterial(materialType: Material.MaterialType) -> Material {
        switch materialType {
            case .random:
                return createMaterial(materialType: [MaterialType.solid, MaterialType.metallic, MaterialType.wacky].randomElement()!)
            case .randomNormal:
                return createMaterial(materialType: [MaterialType.solid, MaterialType.metallic].randomElement()!)
            case .metallic:
                let color = SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
                let metallicness = Float.random(in: 0.9...1)
                return Material(albedo: color * (1 - metallicness), specular: color * metallicness, n: 1, transparency: 0)
            case .solid:
                let color = SIMD3<Float>(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
                let metallicness = Float.random(in: 0...0.1)
                return Material(albedo: color * (1 - metallicness), specular: color * metallicness, n: 1, transparency: 0)
            case .wacky:
                return Material(albedo: SIMD3<Float>(Float.random(in: 0...1),
                                                     Float.random(in: 0...1),
                                                     Float.random(in: 0...1)),
                                specular: SIMD3<Float>(Float.random(in: 0...1),
                                                       Float.random(in: 0...1),
                                                       Float.random(in: 0...1)),
                                n: 1,
                                transparency: 0)
            default:
                return Material(albedo: SIMD3<Float>(1,1,1), specular: SIMD3<Float>(1,1,1), n: 1, transparency: 0)
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
    
    static func sphere(materialType: Material.MaterialType, position: SIMD3<Float>, size: SIMD3<Float>) -> Object {
        return Object(objectType: ObjectType.Sphere.rawValue,
                      position: position,
                      size: SIMD3<Float>(size.x, 0, 0),
                      rotation: SIMD3<Float>(0, 0, 0),
                      material: Material.createMaterial(materialType: materialType))
    }
    
    static func box(materialType: Material.MaterialType, minPosition: SIMD2<Float>, maxPosition: SIMD2<Float>) -> Object {
        let height = Float.random(in: 1...10)
        let position = SIMD3<Float>(Float.random(in: minPosition.x...maxPosition.x), height, Float.random(in: minPosition.y...maxPosition.y))
        return Object(objectType: ObjectType.Box.rawValue,
                      position: position,
                      size: SIMD3<Float>(Float.random(in: 1...10), height, Float.random(in: 1...10)),
                      rotation: SIMD3<Float>(0, 0, 0),
                      material: Material.createMaterial(materialType: materialType))
    }
    static func box(materialType: Material.MaterialType, position: SIMD3<Float>, size: SIMD3<Float>) -> Object {
        return Object(objectType: ObjectType.Box.rawValue,
                      position: position,
                      size: size,
                      rotation: SIMD3<Float>(0, 0, 0),
                      material: Material.createMaterial(materialType: materialType))
    }
    
    enum ObjectType: Int32 {
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
    
    var radius: Float {
        if objectType == ObjectType.Sphere.rawValue {
            return size.x
        } else {
            return pow(pow(size.x, 2) + pow(size.y, 2) + pow(size.z, 2), 0.5)
        }
    }
    
    static func intersect(object1: Object, object2: Object) -> Bool {
        return length(object1.position - object2.position) < object1.radius + object2.radius
    }
}

struct Scene {
    
}
