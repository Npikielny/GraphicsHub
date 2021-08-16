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
// http://download.nvidia.com/developer/SDK/Individual_Samples/DEMOS/OpenGL/src/gpgpu_fluid/Docs/GPU_Gems_Fluids_Chapter.pdf
// https://github.com/keijiro/StableFluids.git
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

float2 flip(float2 in) {
    return float2(in.y, in.x);
}
float2 flip(int2 in) {
    return float2(in.y, in.x);
}

float4 bilinearInterpolation(float2 uv, // does not work for coordinates in max row or max column
                             texture2d<float, access::read_write> image) {
    float2 coord = uv * float2(imageSize(image));
    uint2 minCoord = uint2(coord);
    return lerp(lerp(image.read(minCoord), image.read(minCoord + uint2(1, 0)), fract(coord.x)),
                lerp(image.read(minCoord + uint2(0, 1)), image.read(minCoord + uint2(1, 1)), fract(coord.x)),
                fract(coord.y));
    
    
}

//void advect(uint2 tid,
//              float dt,
//              texture2d<float> velocityIn,
//              texture2d<float, access::read_write> velocityOut) {
//    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
////    float2 coords = float2(tid) / float2(imageSize(velocity)); // converts from tid to UV
////    // velocity field in previous state
////    float2 pos = float2(coords) - dt / gridScale * velocity.read(tid).xy;
////
////    return bilinearInterpolation(pos, advectingQuantity);
//
//    float2 uv = (float2(tid) + 0.5) / float2(imageSize(velocityIn));
//
//    float2 velocityChange = velocityIn.read(tid).xy * float2(float(velocityIn.get_height()) / float(velocityIn.get_width()), 1) * dt; // travel distance of previous fluid iteration in UV
//    velocityOut.write(velocityIn.sample(sam, uv - velocityChange), tid);
//}

kernel void initialize(uint2 tid [[ thread_position_in_grid ]],
                       texture2d<float, access::write> v1,
                       texture2d<float, access::write> v2,
                       texture2d<float, access::write> v3,
                       texture2d<float, access::write> p1,
                       texture2d<float, access::write> p2,
                       texture2d<float, access::write> dye) {
    v1.write(float4(float3(0), 1), tid);
    v2.write(float4(float3(0), 1), tid);
    v3.write(float4(float3(0), 1), tid);
    p1.write(float4(float3(0), 1), tid);
    p2.write(float4(float3(0), 1), tid);
    dye.write(float4(float2(tid)/float2(imageSize(dye)), 0, 1), tid);
//    dye.write(float4(hash(tid.x * tid.y + tid.y), hash(tid.x * tid.y + tid.x), 0, 1), tid);
    
}

kernel void advect(uint2 tid                                              [[ thread_position_in_grid ]],
                   constant float & dt                                    [[ buffer (0) ]],
                   texture2d<float> U_in                            [[ texture (0) ]],
                   texture2d<float, access::read_write> W_out       [[ texture (1) ]]
                   ) {
    constexpr sampler sam(min_filter::linear, mag_filter::linear, mip_filter::none);
    float2 uv = (float2(tid) + 0.5) / float2(imageSize(U_in));
    
    
    float2 velocityChange = U_in.read(tid).xy * float2((float)U_in.get_height() / U_in.get_width(), 1) * dt; // travel distance of previous fluid iteration in UV
    W_out.write(U_in.sample(sam, uv - velocityChange), tid);
    
    
//    float2 uv = (float2(tid) + 0.5) / float2(imageSize(U_in));
//    float2 duv = U_in.read(tid).xy * float2((float)U_in.get_height() / U_in.get_width(), 1) * dt; // travel distance of previous fluid iteration in UV
//    float2 location = (uv - duv) * float2(imageSize(U_in));
//    float2 minLocation = floor(location - 0.5);
//    float2 percents = fract(location);
//
//    W_out.write(lerp(lerp(U_in.read(uint2(minLocation)), U_in.read(uint2(minLocation + float2(1, 0))), percents.x),
//                     lerp(U_in.read(uint2(minLocation + float2(0, 1))), U_in.read(uint2(minLocation + float2(1, 1))), percents.x),
//                     percents.y),
//                tid);
}

float4 jacobi(uint2 tid, // location
              float alpha, // looks like center bias (δx)^2/νδt
              float rBeta, // reciprocal beta  1/(4 + (δx)^2/νδt)
              texture2d<float, access::read_write>x, // Ax = b
              texture2d<float, access::read_write>b) { // x and b are velocity textures (20 - 50 iterations)
    // adjacent values
    float4 left = x.read(tid - uint2(1, 0));
    float4 right = x.read(tid + uint2(1, 0));
    float4 below = x.read(tid - uint2(0, 1));
    float4 above = x.read(tid + uint2(0, 1));
    
    // center
    float4 center = x.read(tid);
    
    // jacobi output
    return (left + right + below + above + alpha * center) * rBeta;
}

kernel void jacobiVector(uint2 tid                           [[ thread_position_in_grid ]],
                   constant float & alpha              [[ buffer (0) ]],
                   constant float & beta               [[ buffer (1) ]],
                   texture2d<float> X1_in                 [[ texture (0) ]],
                   texture2d<float, access::write> X1_out [[ texture (1) ]],
                   texture2d<float> B1_in                  [[ texture (2) ]]) {
    X1_out.write(float4(
              (X1_in.read(tid - uint2(1, 0)).xy + X1_in.read(tid + uint2(1, 0)).xy +
              X1_in.read(tid - uint2(0, 1)).xy + X1_in.read(tid + uint2(0, 1)).xy +
               alpha * B1_in.read(tid).xy) / beta,
                 0,
                 1),
              tid);
}

kernel void force(uint2 tid                                     [[ thread_position_in_grid ]],
                  constant float2 & forceVector                 [[ buffer (0) ]],
                  constant float2 & forceOrigin                 [[ buffer (1) ]],
                  constant float & forceExponent                [[ buffer (2) ]],
                  texture2d<float, access::read> velocityIn     [[ texture (0) ]],
                  texture2d<float, access::write> velocityOut   [[ texture (1) ]]) {
    int2 dimensions = imageSize(velocityIn);
    
    float2 pos = float2(tid) / float2(dimensions) - 0.5;
    float amp = exp(-forceExponent * distance(forceOrigin, float2(pos)));

    velocityOut.write(velocityIn.read(tid) + float4(forceVector * amp, 0, 0), tid);
    
}

kernel void projectionSetup(uint2 tid [[thread_position_in_grid]],
                            texture2d<float> W_in [[ texture (0) ]],
                            texture2d<float, access::write> DivW_out [[ texture (1) ]],
                            texture2d<float, access::write> P_out [[ texture (2) ]]) {
//    DivW_out.write(float4(
//                          float2(
//                                 (W_in.read(tid + uint2(1, 0)).x - W_in.read(tid - uint2(1, 0)).x +
//                                  W_in.read(tid + uint2(0, 1)).y - W_in.read(tid - uint2(0, 1)).y) * float(W_in.get_height()) / 2
//                                 ),
//                          0,
//                          1),
//                  tid);
    DivW_out.write(float4(
                          float2(
                                 W_in.read(tid + uint2(1, 0)).x - W_in.read(tid - uint2(1, 0)).x +
                                 W_in.read(tid + uint2(0, 1)).y - W_in.read(tid - uint2(0, 1)).y
                                 ) * W_in.get_height() / 2,
//                          float2(
//                                 W_in.read(tid + uint2(1, 0)).x - W_in.read(tid - uint2(1, 0)).x +
//                                 W_in.read(tid + uint2(0, 1)).y - W_in.read(tid - uint2(0, 1)).y
//                                 ),
                          0,
                          1),
                   tid);
    P_out.write(float4(float3(0), 1), tid);
}

kernel void jacobiScalar(uint2 tid                           [[ thread_position_in_grid ]],
                   constant float & alpha              [[ buffer (0) ]],
                   constant float & beta               [[ buffer (1) ]],
                   texture2d<float> X1_in                 [[ texture (0) ]],
                   texture2d<float, access::write> X1_out [[ texture (1) ]],
                   texture2d<float> B1_in                  [[ texture (2) ]]) {
    X1_out.write(
              (X1_in.read(tid - uint2(1, 0)).x + X1_in.read(tid + uint2(1, 0)).x +
              X1_in.read(tid - uint2(0, 1)).x + X1_in.read(tid + uint2(0, 1)).x +
               alpha * B1_in.read(tid).x) / beta,
              tid);
}

kernel void projectionFinish(uint2 tid [[ thread_position_in_grid ]],
                             texture2d<float> W_in [[ texture (0) ]],
                             texture2d<float> P_in [[ texture (1) ]],
                             texture2d<float, access::read_write> U_out [[ texture (2) ]]) {
    uint2 dimensions = uint2(imageSize(W_in));
    if (any(tid == 0) || any(tid == dimensions - 1)) { return; }
    
    float p1 = P_in.read(max(tid - uint2(1, 0), 1)).x;
    float p2 = P_in.read(min(tid + uint2(1, 0), dimensions - 2)).x;
    float p3 = P_in.read(max(tid - uint2(1, 0), 1)).x;
    float p4 = P_in.read(min(tid - uint2(1, 0), dimensions - 2)).x;
    
    float2 velocity = W_in.read(tid).xy - float2(p2 - p1, p4 - p3) * W_in.get_height() / 2;
    
    U_out.write(float4(velocity, 0, 1), tid);

    if (tid.x == 1) { U_out.write(float4(-velocity, 0, 1), uint2(0, tid.y)); }
    if (tid.y == 1) { U_out.write(float4(-velocity, 0, 1), uint2(tid.x, 0)); }
    if (tid.x == dimensions.x - 2) { U_out.write(float4(-velocity, 0, 1), uint2(dimensions.x - 1, tid.y)); }
    if (tid.y == dimensions.y - 2) { U_out.write(float4(-velocity, 0, 1), uint2(tid.x, dimensions.y - 1)); }
}

float3 trilerp(float3 a, float3 b, float3 c, float p) {
    if (p < 0) {
        return lerp(a, b, 1 - p);
    } else {
        return lerp(b, a, p);
    }
}

float3 velocityColor(float2 velocity) {
    float3 xColor = trilerp(float3(1, 0, 0), 1., float3(0, 0, 1), velocity.x);
    float3 yColor = trilerp(float3(0, 1, 0), 1., float3(1, 1, 1), velocity.y);
    return xColor * abs(velocity.x) + yColor * float(velocity.y);
}

kernel void moveDye(uint2 tid [[ thread_position_in_grid ]],
                      texture2d<float> velocity,
                      texture2d<float> previousDye,
                      texture2d<float, access::write> dye) {
//    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
//    dye.write(abs(velocity.sample(sam, (float2(tid) + 0.5)/float2(imageSize(dye)))), tid);
//    dye.write(previousDye.read(uint2(float2(tid) - velocity.read(tid).xy)), tid);
//    float2 v = velocity.read(tid).xy;
//    float mag = length(v);
//    v = normalize(v);
//    v = v * 0.5 + 0.5;
//    float3 color = (velocityColor(v) * pow(mag, 0.5));
//
//    dye.write(float4(color, 1), tid);
    dye.write(abs(velocity.read(tid)), tid);
//    dye.write(abs(velocity.read(tid)), tid);
}

float4 divergence(uint2 tid, // location,
                float halfrdx, // 0.5 / gridScale,
                texture2d<float, access::read_write> w // some vector field
                ) {
    // adjacent values
    float4 left = w.read(tid - uint2(1, 0));
    float4 right = w.read(tid + uint2(1, 0));
    float4 below = w.read(tid - uint2(0, 1));
    float4 above = w.read(tid + uint2(0, 1));
    return halfrdx * ((right.x - left.x) + (above.y - below.y));
}

float4 gradient(uint2 tid, // location
                float halfrdx, // 0.5 / gridscale
                texture2d<float, access::read_write> pressure,
                texture2d<float, access::read_write> velocity
                ) {
    // adjacent values
    float left = pressure.read(tid - uint2(1, 0)).x;
    float right = pressure.read(tid + uint2(1, 0)).x;
    float below = pressure.read(tid - uint2(0, 1)).x;
    float above = pressure.read(tid + uint2(0, 1)).x;
    
    float4 output = velocity.read(tid);
    output.xy -= halfrdx * float2(right - left, above - below);
    return output;
}

float4 boundary(uint2 tid,
                int2 offset,
                float scale,
                texture2d<float, access::read_write> state // state field
                ) {
    return scale * state.read(uint2(int2(tid) + offset));
}

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

//int index(int2 coords, int width) { return coords.x + coords.y * width; }

//kernel void populateVelocities(uint2 tid    [[thread_position_in_grid]],
//                               constant int2 & imageSize  [[buffer(0)]],
//                               device float2 * velocities [[buffer(1)]]) {
//    if (tid.x < 1 || tid.y < 1 || tid.x == uint(imageSize.x - 1) || tid.y == uint(imageSize.y - 1)) {
//        velocities[index(tid, imageSize)] = float2(0);
//    } else {
//        velocities[index(tid, imageSize)] = float2(
//                                                   hash(tid.x + tid.y * imageSize.x),
//                                                   hash(tid.x + tid.y * imageSize.x + imageSize.x * imageSize.y)
//                                                   ) - 0.5;
//    }
//}

//kernel void fluidSimulation(uint2 tid                                       [[ thread_position_in_grid ]],
//                            constant float & dt                             [[ buffer(0) ]],
//                            texture2d<float, access::read_write> image      [[ texture(0) ]],
//                            texture2d<float, access::read_write> density    [[ texture(1) ]],
//                            texture2d<float, access::read_write> velocities [[ texture(2) ]]
//                            ) {
//
//    velocities.write(
//                     advect(
//                            tid,
//                            dt,
//                            <#float gridScale#>,
//                            velocities,
//                            velocities),
//                     tid);
//    velocities.write(<#vec<float, 4> color#>, <#ushort2 coord#>)
//
//    advect(<#uint2 tid#>, <#float dt#>, <#float gridScale#>, <#texture2d<float, access::read_write> velocity#>, <#texture2d<float, access::read_write> advectingQuantity#>)
////    // Apply the first 3 operators in Equation 12.
////    u = advect(u);
////    u = diffuse(u);
////    u = addForces(u);
////    // Now apply the projection operator to the result. p = computePressure(u);
////    u = subtractPressureGradient(u, p);
//
//
//
//
//
////    if (tid.x > uint(imageSize.x) || tid.y > uint(imageSize.y)) { return; }
////    if (tid.x < 1 || tid.y < 1 || tid.x == uint(imageSize.x - 1) || tid.y == uint(imageSize.y - 1)) {
////        // edge case
////    } else {
////
////    }
////    int2 pos = clamp(int2(float2(tid) - velocities[index(tid, imageSize)] * 10), int2(0), imageSize - 1);
////////    int2 pos = int2(tid);
////    float3 color = density.read(uint2(pos)).xyz;
//////    if (length(color) < 0.1) {
//////        color = float3(0);
//////    }
//////    image.write(float4(color, 1), tid);
////
////    image.write(float4(color, 1), tid);
////
////
//////    // Apply the first 3 operators in Equation 12.
//////    velocity = advect(velocity);
//////    velocity = diffuse(velocity);
//////    velocity = addForces(velocity);
//////    // Now apply the projection operator to the result.
//////    pressure = computePressure(velocity);
//////    velocity = subtractPressureGradient(velocity, pressure);
//////    float2 position = float2(tid) * fluidSize / float2(imageSize) / 2.0 * velocity.read(tid).xy;
////
////
////
////    // MARK: Mike Ash
////    // diffuse velocities
////    // project velocities
////    // advect velocities
////    // project velocities
////
////    // diffuse density
////    // advect densities
////
//////    image.write(float4(1, 0, 0, 1), tid);
//}
