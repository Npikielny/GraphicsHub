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
}

struct Sphere {
    var position: SIMD4<Float>
    var material: Material
}

struct Scene {
    
}
