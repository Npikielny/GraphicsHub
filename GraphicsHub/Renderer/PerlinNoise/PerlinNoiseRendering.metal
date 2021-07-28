//
//  PerlinNoiseRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/25/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../Shared/SharedDataTypes.h"
#include "Perlin.h"

constant float3 colors[] = {
    float3(0, 0, 0.4),  // Deep
    float3(0, 0, 1),    // Water
    float3(1, 0.8, 0),  // Sand
    float3(0, 0.75, 0), // Grass
    float3(0, 0.5, 0),  // Forest
};

kernel void perlinRenderer(uint2 tid [[thread_position_in_grid]],
                           constant int & octaves [[buffer(0)]],
                           constant int2 & noise [[buffer(1)]],
                           constant int & noiseSeed [[buffer(2)]],
                           constant int & seed [[buffer(3)]],
                           constant float & p [[buffer(4)]],
                           constant float & zoom [[buffer(5)]],
                           constant float4 & v [[buffer(6)]],
                           texture2d<float, access::read_write> image) {
    float value = perlin(int2(tid), image.get_width(), octaves, noise.x, noise.y, noiseSeed, zoom);
    
//    perlinNoise(float2(tid), int(), image.get_width(), int2(1619, 31337), 1013, 1);
//    image.write(float4(float3(interpolateColors(colors, 5, value * 2)), 1), tid);
    image.write(float4(float3(value), 1), tid);
//    image.write(float4(float3(value), 1), tid);
}
