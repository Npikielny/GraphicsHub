//
//  FluidRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/21/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../Shared/SharedDataTypes.h"

//Source: https://developer.download.nvidia.com/books/HTML/gpugems/gpugems_ch38.html

//void advect(uint2 tid,
//            float2 fluidSize,
//            int2 imageSize,
//            thread float2 & position,
//            texture2d<float, access::read_write> velocity,
//            texture2d<float, access::read_write> advecting) {
//    position = advecting.read(uint2(float2(tid) * fluidSize / float2(imageSize) / 2.0 * velocity.read(tid).xy)).xy;
//}
int index(uint2 tid, int2 imageSize) {
    return tid.x + tid.y * imageSize.x;
}
int index(int2 tid, int2 imageSize) {
    return tid.x + tid.y * imageSize.x;
}

template<typename T>
inline T lerp(T a, T b, float p) {
    return (b - a) * p + a;
}

float4 bilinearInterpolation(float2 uv, // does not work for coordinates in max row or max column
                             texture2d<float, access::read_write> image) {
    float2 coord = uv * float2(imageSize(image));
    uint2 minCoord = uint2(coord);
    return lerp(lerp(image.read(minCoord), image.read(minCoord + uint2(1, 0)), fract(coord.x)),
                lerp(image.read(minCoord + uint2(0, 1)), image.read(minCoord + uint2(1, 1)), fract(coord.x)),
                fract(coord.y));
    
    
}

float4 advect(uint2 tid,
              float dt,
              float gridScale,
              texture2d<float, access::read_write> velocity,
              texture2d<float, access::read_write> advectingQuantity) {
    float2 coords = float2(tid) / float2(imageSize(velocity)); // converts from tid to UV
    // velocity field in previous state
    float2 pos = float2(coords) - dt / gridScale * velocity.read(tid).xy;

    return bilinearInterpolation(pos, advectingQuantity);
}

float4 jacobi() {}

void boundary(int2 location, device float2 * velocity, int2 imageSize) {
    bool isHorizontalEdge = (location.x == 0 || location.x == imageSize.x - 1);
    bool isVerticalEdge = location.y == 0 || location.y == imageSize.y - 1;
    if (isHorizontalEdge && isVerticalEdge) {
        velocity[index(location, imageSize)] = 0.0;
        if (location.x == 0) {
            velocity[index(location, imageSize)] += velocity[index(location + int2(1, 0), imageSize)] / 2;
        } else {
            velocity[index(location, imageSize)] += velocity[index(location - int2(1, 0), imageSize)] / 2;
        }
        if (location.y == 0) {
            velocity[index(location, imageSize)] += velocity[index(location + int2(0, 1), imageSize)] / 2;
        } else {
            velocity[index(location, imageSize)] += velocity[index(location - int2(0, 1), imageSize)] / 2;
        }
    } else if (isVerticalEdge) {
        if (location.y == 0) {
            velocity[index(location, imageSize)] = -velocity[index(location + int2(0, 1), imageSize)];
        } else {
            velocity[index(location, imageSize)] = -velocity[index(location - int2(0, 1), imageSize)];
        }
    } else if (isHorizontalEdge) {
        if (location.x == 0) {
            velocity[index(location, imageSize)] = -velocity[index(location + int2(1, 0), imageSize)];
        } else {
            velocity[index(location, imageSize)] = -velocity[index(location - int2(1, 0), imageSize)];
        }
    }
}

void lin_solve(int b,
               device float2 * x,
               constant float2 * x0,
               float2 a,
               float2 c,
               int2 imageSize,
               int2 location) {
    // FIXME: Boundaries
    x[index(location, imageSize)] = (x0[index(location, imageSize)] + a * (x[index(location + int2(1, 0), imageSize)] +
                                                                          x[index(location + int2(-1, 0), imageSize)] +
                                                                          x[index(location + int2(0, 1), imageSize)] +
                                                                          x[index(location + int2(0, -1), imageSize)])) / c;
//    boundary(location, x, imageSize);
}

void diffuse(int b, device float2 * velocity, constant float2 * previousVelocity, float diff, float dt, int2 imageSize, int2 location) {
    float2 a = dt * diff * float2((imageSize - 2) * (imageSize - 2));
    lin_solve(b, velocity, previousVelocity, a, 1 + 6 * a, imageSize, location);
}


void project(device float2 * velocity, constant float * p, int2 imageSize, int2 location) {
//    p[index(location, imageSize)];  
}
//template<typename T>
//T jacobi() {
//
//}


//
//void jacobi(uint2 tid,
//            texture2d<float, access::read_write> x,
//            texture2d<float, access::read_write> b,
//            float alpha,
//            float rBeta,
//            thread float4 & position) {
//    float4 xL = x.read(tid - uint2(1, 0));
//    float4 xR = x.read(tid + uint2(1, 0));
//    float4 xB = x.read(tid - uint2(0, 1));
//    float4 xT = x.read(tid + uint2(0, 1));
//
//    float4 bC = b.read(tid);
//
//    position = (xL + xR + xB + xT + alpha * bC) * rBeta;
//}
//
//void divergence(uint2 coords,
//                float halfrdx,
//                thread float4 & div,
//                texture2d<float> vectorField) {
//    float4 wL = vectorField.read(coords - uint2(1, 0));
//    float4 wR = vectorField.read(coords + uint2(1, 0));
//    float4 wB = vectorField.read(coords - uint2(0, 1));
//    float4 wT = vectorField.read(coords + uint2(0, 1));
//    div = halfrdx * ((wR.x - wL.x) + (wT.y - wB.y));
//}
//
//void gradient(uint2 coords,
//              float halfrdx,
//              thread float4 & uNew,
//              texture2d<float> pressure,
//              texture2d<float> velocity) {
//    float pL = pressure.read(coords - uint2(1, 0)).x;
//    float pR = pressure.read(coords + uint2(1, 0)).x;
//    float pB = pressure.read(coords - uint2(0, 1)).x;
//    float pT = pressure.read(coords + uint2(0, 1)).x;
//
//    uNew = velocity.read(coords);
//    uNew.xy -= halfrdx * float2(pR - pL, pT - pB);
//}
//
//void boundary(float2 coords,
//              float2 offset,
//              thread float4 & bv,
//              float scale,
//              texture2d<float>stateField) {
//    bv = scale * stateField.read(uint2(coords + offset));
//}

int index(int2 coords, int width) { return coords.x + coords.y * width; }

kernel void populateVelocities(uint2 tid    [[thread_position_in_grid]],
                               constant int2 & imageSize  [[buffer(0)]],
                               device float2 * velocities [[buffer(1)]]) {
    if (tid.x < 1 || tid.y < 1 || tid.x == uint(imageSize.x - 1) || tid.y == uint(imageSize.y - 1)) {
        velocities[index(tid, imageSize)] = float2(0);
    } else {
        velocities[index(tid, imageSize)] = float2(
                                                   hash(tid.x + tid.y * imageSize.x),
                                                   hash(tid.x + tid.y * imageSize.x + imageSize.x * imageSize.y)
                                                   ) - 0.5;
    }
}

kernel void fluidSimulation(uint2 tid                                     [[ thread_position_in_grid ]],
                            constant int2 & imageSize                                [[ buffer(0) ]],
                            device float2 * velocities                               [[ buffer(1) ]],
                            texture2d<float, access::read_write> image    [[ texture(0) ]],
                            texture2d<float, access::read_write> density [[texture(1)]] // Ink
                            ) {
    
    if (tid.x > uint(imageSize.x) || tid.y > uint(imageSize.y)) { return; }
    if (tid.x < 1 || tid.y < 1 || tid.x == uint(imageSize.x - 1) || tid.y == uint(imageSize.y - 1)) {
        // edge case
    } else {

    }
    int2 pos = clamp(int2(float2(tid) - velocities[index(tid, imageSize)] * 10), int2(0), imageSize - 1);
////    int2 pos = int2(tid);
    float3 color = density.read(uint2(pos)).xyz;
//    if (length(color) < 0.1) {
//        color = float3(0);
//    }
//    image.write(float4(color, 1), tid);
    
    image.write(float4(color, 1), tid);
    
    
//    // Apply the first 3 operators in Equation 12.
//    velocity = advect(velocity);
//    velocity = diffuse(velocity);
//    velocity = addForces(velocity);
//    // Now apply the projection operator to the result.
//    pressure = computePressure(velocity);
//    velocity = subtractPressureGradient(velocity, pressure);
//    float2 position = float2(tid) * fluidSize / float2(imageSize) / 2.0 * velocity.read(tid).xy;
    
    
    
    // MARK: Mike Ash
    // diffuse velocities
    // project velocities
    // advect velocities
    // project velocities
    
    // diffuse density
    // advect densities
    
//    image.write(float4(1, 0, 0, 1), tid);
}
