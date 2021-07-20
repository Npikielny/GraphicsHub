//
//  3DRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/16/21.
//

import SceneKit
import GameplayKit

class SceneManager {
    
    enum GenerationType {
        case procedural
        case random
    }
    
    enum PositionType {
        case radial
        case box
    }
    
    enum CollisionType {
        case grounded
        case distinct
        case intersecting
        case random
    }
    
    static func concentric(radials: Int, objectTypes: [Object.ObjectType], materialType: Material.MaterialType) -> [Object] {
        assert(!objectTypes.contains(.Triangle))
        
        var objects = [Object]()
        let radius: (Float) -> (Float) = { return 15 / powf(1.1, 0.4 * Float($0))}

        for Radius in 0..<radials {
            let rad = radius(Float(Radius) * 40 / 5)
            var innerRadiusSize: Float = 0
            for k in 0...Radius {
                innerRadiusSize += 2*radius(Float(k) * 40 / 5) * 1.1
            }
            let radialCount: Int = {
                return Int(innerRadiusSize / rad)*3
            }()
            for k in 0..<radialCount {
                let theta: Float = Float(k)/Float(radialCount)*Float.pi*2
                let position = SIMD3<Float>(innerRadiusSize * cos(theta), rad, innerRadiusSize * sin(theta))
                let size: SIMD3<Float> = SIMD3(rad, 0, 0)
                objects.append(Object.newObject(materialType: materialType, position: position, size: size, rotation: SIMD3<Float>(0, 0, 0), objectType: objectTypes.randomElement()!))
            }
        }

        let Radius = 0
        let rad = radius(Float(Radius)*40/5-4)
        let position = SIMD3<Float>(0,rad,0)
        let size: SIMD3<Float> = SIMD3(rad, 0, 0)
        objects.append(Object.sphere(materialType: materialType, position: position, size: size))
        return objects
    }
    
    static func generate(objectCount: Int, objectTypes: [Object.ObjectType], generationType:  GenerationType, positionType: PositionType, collisionType: [CollisionType], objectSizeRange: (SIMD3<Float>, SIMD3<Float>), objectPositionRange: (SIMD3<Float>, SIMD3<Float>), materialType: Material.MaterialType) -> [Object] {
        var objects = [Object]()
        var iterations: Int = 0
        
        let positionGenerator: (Float, Float) -> SIMD2<Float> = {
            if positionType == .radial {
                return { radialGenerate(seed: ($0, $1), objectPositionRange: objectPositionRange) }
            } else {
                return { boxGenerate(seed: ($0, $1), objectPositionRange: objectPositionRange) }
            }
        }()
        let generator = GKARC4RandomSource()
        let generate: () -> Float = { Float(generator.nextInt(upperBound: 1000))/1000 }
        
        while objects.count < objectCount && iterations < 10000 {
            iterations += 1
            let xzPosition: SIMD2<Float> = {
                if generationType == .procedural {
                    return positionGenerator(generate(), generate())
                } else {
                    return positionGenerator(Float.random(in: 0...1), Float.random(in: 0...1))
                }
            }()
            
            guard let objectTypes = objectTypes.randomElement() else { continue }
            
            let size: SIMD3<Float> = {
                if generationType == .procedural {
                    return SIMD3<Float>(
                        Float.lerp(a: objectSizeRange.0.x, b: objectSizeRange.1.x, p: generate()),
                        Float.lerp(a: objectSizeRange.0.y, b: objectSizeRange.1.y, p: generate()),
                        Float.lerp(a: objectSizeRange.0.z, b: objectSizeRange.1.z, p: generate()))
                }else {
                    return SIMD3(
                        Float.random(in: objectSizeRange.0.x...objectSizeRange.1.x),
                        Float.random(in: objectSizeRange.0.y...objectSizeRange.1.y),
                                     Float.random(in: objectSizeRange.0.z...objectSizeRange.1.z)
                    )
                }
            }()
            
            let position: SIMD3<Float> = {
                if collisionType.contains(.grounded) {
                    return SIMD3(xzPosition.x, objectTypes == .Sphere ? size.x : size.y / 2, xzPosition.y)
                } else {
                    return SIMD3(xzPosition.x,
                                 Float.lerp(a: objectPositionRange.0.y, b: objectPositionRange.1.y, p: generationType == .procedural ? generate() : Float.random(in: 0...1)),
                                 xzPosition.y)
                }
            }()
            
            if objectTypes == .Triangle {
                let length = Float.lerp(a: objectSizeRange.0.x, b: objectSizeRange.1.x, p: generate())
                let theta = Float.random(in: 0...Float.pi * 2)
                let matrix = float3x3([SIMD3<Float>(cos(theta), 0, sin(theta)),
                                       SIMD3<Float>(0, 1, 0),
                                       SIMD3<Float>(-sin(theta), 0, cos(theta))] )
//                    let matrix = float3x3([SIMD3(1, 0, 0),
//                                           SIMD3(0, 1, 0),
//                                           SIMD3(0, 0, 1)])
//
                let v0 = position + SIMD3(0, 0, length) - SIMD3(0, position.y, 0)
                let v1 = position + SIMD3(length / pow(3, 0.5) * 2, 0, -length / pow(3, 0.5)) * matrix - SIMD3(0, position.y, 0)
                let v2 = position + SIMD3(-length / pow(3, 0.5) * 2, 0, -length / pow(3, 0.5)) * matrix - SIMD3(0, position.y, 0)
                let v3 = position + SIMD3(0, length, 0) * matrix - SIMD3(0, position.y, 0)
                
                let material = Material.createMaterial(materialType: materialType)
                
                let t1 = Object.triangle(material: material, v0: v0, v1: v1, v2: v2)
                let collision = objects.contains(where: { Object.intersect(object1: $0, object2: t1) })
                if (collision && collisionType.contains(.distinct)) || (!collision && collisionType.contains(.intersecting)) {
                    continue
                }
                
                objects.append(t1)
                objects.append(Object.triangle(material: material, v0: v0, v1: v1, v2: v3))
                objects.append(Object.triangle(material: material, v0: v0, v1: v3, v2: v2))
                objects.append(Object.triangle(material: material, v0: v3, v1: v1, v2: v2))
                continue
            }
            
            let object = Object.newObject(materialType: materialType,
                                          position: position,
                                          size: size,
                                          rotation: SIMD3<Float>(0, Float.random(in: 0...Float.pi * 2), 0),
                                          objectType: objectTypes)
            
            let collision = objects.contains(where: { Object.intersect(object1: $0, object2: object) })
            if (collision && collisionType.contains(.distinct)) || (!collision && collisionType.contains(.intersecting)) {
                continue
            }
            objects.append(object)
        }
        print("Generated: ", objects.count)
        return objects
    }
    
    static func marchGenerate(locations: [SIMD3<Float>], materialType: Material.MaterialType) -> [Object] {
        var objects = [Object]()
        
        for location in locations {
            objects.append(Object(objectType: Int32([0, 1, 3, 6].randomElement()!),
                                  position: location,
                                  size: SIMD3<Float>(1, 1, 1),
                                  rotation: SIMD3<Float>(Float.random(in: 0...Float.pi * 2), Float.random(in: 0...Float.pi * 2), Float.random(in: 0...Float.pi * 2)),
                                  material: Material.createMaterial(materialType: materialType)))
        }
        
        return objects
    }
    
    private static func radialGenerate(seed: (Float, Float), objectPositionRange: (SIMD3<Float>, SIMD3<Float>)) -> SIMD2<Float> {
        // R, Theta, Phi
        let r = Float.lerp(a: objectPositionRange.0.x, b: objectPositionRange.1.x, p: seed.0)
        let theta = Float.lerp(a: objectPositionRange.0.y, b: objectPositionRange.1.y, p: seed.1)
        return SIMD2<Float>(r * cos(theta), r * sin(theta))
    }
    
    private static func boxGenerate(seed: (Float, Float), objectPositionRange: (SIMD3<Float>, SIMD3<Float>)) -> SIMD2<Float> {
        return SIMD2<Float>(
            Float.lerp(a: objectPositionRange.0.x, b: objectPositionRange.1.x, p: seed.0),
            Float.lerp(a: objectPositionRange.0.z, b: objectPositionRange.1.z, p: seed.1)
        )
    }
    
//    private static func distinct() -> [Object] {
//        var spheres = [Object]()
//        for _ in 0...Int.random(in: 10...30) {
//            for _ in 0...10 {
//                let sphere = Object.sphere(materialType: .random, minPosition: SIMD2<Float>(-25, -25), maxPosition: SIMD2<Float>(25, 25))
//                if !spheres.contains(where: {  length($0.position - sphere.position) < $0.radius + sphere.radius }) {
//                    spheres.append(sphere)
//                    continue
//                }
//            }
//
//        }
//        return spheres
//    }
//
//    private static func random(count: Int, minPosition: SIMD2<Float>, maxPosition: SIMD2<Float>, materialType: Material.MaterialType) -> [Object] {
//        var objects = [Object]()
//        for _ in 0..<count {
//            switch Int.random(in: 0..<3) {
//                case 0:
//                    objects.append(Object.sphere(materialType: materialType,
//                                                 minPosition: minPosition,
//                                                 maxPosition: maxPosition))
//                case 1:
//                    objects.append(Object.box(materialType: materialType,
//                                              minPosition: minPosition,
//                                              maxPosition: maxPosition))
//                default:
//                    objects.append(Object.sphere(materialType: materialType,
//                                                 minPosition: minPosition,
//                                                 maxPosition: maxPosition))
//            }
//        }
//        return objects
//    }
}

