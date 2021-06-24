//
//  Transforms.swift
//
//  Created by Marius Horga on 7/7/18.
//

import simd

func translate(tx: Float, ty: Float, tz: Float) -> float4x4 {
  return float4x4(
    SIMD4<Float>( 1,  0,  0,  0),
    SIMD4<Float>( 0,  1,  0,  0),
    SIMD4<Float>( 0,  0,  1,  0),
    SIMD4<Float>(tx, ty, tz,  1)
  )
}

func rotate(radians: Float, axis: SIMD3<Float>) -> float4x4 {
  let normalizedAxis = normalize(axis)
  let ct = cosf(radians)
  let st = sinf(radians)
  let ci = 1 - ct
  let x = normalizedAxis.x, y = normalizedAxis.y, z = normalizedAxis.z
  
  return float4x4(
    SIMD4<Float>(    ct + x * x * ci,  y * x * ci + z * st,  z * x * ci - y * st,  0),
    SIMD4<Float>(x * y * ci - z * st,      ct + y * y * ci,  z * y * ci + x * st,  0),
    SIMD4<Float>(x * z * ci + y * st,  y * z * ci - x * st,      ct + z * z * ci,  0),
    SIMD4<Float>(                  0,                    0,                    0,  1)
  )
}

func scale(sx: Float, sy: Float, sz: Float) -> float4x4 {
  return float4x4(
    SIMD4<Float>(sx,   0,   0,  0),
    SIMD4<Float>( 0,  sy,   0,  0),
    SIMD4<Float>( 0,   0,  sz,  0),
    SIMD4<Float>( 0,   0,   0,  1)
  )
}
