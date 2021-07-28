//
//  FluidRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/21/21.
//

#include <metal_stdlib>
using namespace metal;

//Source: https://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch38.html

void advect(uint2 tid,
            float2 fluidSize,
            int2 imageSize,
            thread float2 & position,
            texture2d<float, access::read_write> velocity,
            texture2d<float, access::read_write> advecting) {
    position = advecting.read(uint2(float2(tid) * fluidSize / float2(imageSize) / 2.0 * velocity.read(tid).xy)).xy;
}

void jacobi(uint2 tid,
            texture2d<float, access::read_write> x,
            texture2d<float, access::read_write> b,
            float alpha,
            float rBeta,
            thread float4 & position) {
    float4 xL = x.read(tid - uint2(1, 0));
    float4 xR = x.read(tid + uint2(1, 0));
    float4 xB = x.read(tid - uint2(0, 1));
    float4 xT = x.read(tid + uint2(0, 1));
    
    float4 bC = b.read(tid);
    
    position = (xL + xR + xB + xT + alpha * bC) * rBeta;
}

void divergence(uint2 coords,
                float halfrdx,
                thread float4 & div,
                texture2d<float> vectorField) {
    float4 wL = vectorField.read(coords - uint2(1, 0));
    float4 wR = vectorField.read(coords + uint2(1, 0));
    float4 wB = vectorField.read(coords - uint2(0, 1));
    float4 wT = vectorField.read(coords + uint2(0, 1));
    div = halfrdx * ((wR.x - wL.x) + (wT.y - wB.y));
}

void gradient(uint2 coords,
              float halfrdx,
              thread float4 & uNew,
              texture2d<float> pressure,
              texture2d<float> velocity) {
    float pL = pressure.read(coords - uint2(1, 0)).x;
    float pR = pressure.read(coords + uint2(1, 0)).x;
    float pB = pressure.read(coords - uint2(0, 1)).x;
    float pT = pressure.read(coords + uint2(0, 1)).x;
    
    uNew = velocity.read(coords);
    uNew.xy -= halfrdx * float2(pR - pL, pT - pB);
}

void boundary(float2 coords,
              float2 offset,
              thread float4 & bv,
              float scale,
              texture2d<float>stateField) {
    bv = scale * stateField.read(uint2(coords + offset));
}

kernel void fluidSimulation(uint2 tid                                     [[ thread_position_in_grid ]],
                            constant int2 & imageSize                                [[ buffer(0) ]],
                            constant float2 & fluidSize [[ buffer(1) ]],
                            texture2d<float, access::read_write> velocity [[ texture(0) ]],
                            texture2d<float, access::read_write> pressure [[ texture(1) ]],
                            texture2d<float, access::read_write> image    [[ texture(2) ]] // ink
                            ) {
    if (tid.x > uint(imageSize.x) || tid.y > uint(imageSize.y)) { return; }
    if (tid.x < 1 || tid.y < 1 || tid.x == uint(imageSize.x - 1) || tid.y == uint(imageSize.y - 1)) {
        // edge case
    } else {
        
    }
//    // Apply the first 3 operators in Equation 12.
//    u = advect(u);
//    u = diffuse(u);
//    u = addForces(u);
//    // Now apply the projection operator to the result.
//    p = computePressure(u);
//    u = subtractPressureGradient(u, p);
    float2 position = float2(tid) * fluidSize / float2(imageSize) / 2.0 * velocity.read(tid).xy;
}
