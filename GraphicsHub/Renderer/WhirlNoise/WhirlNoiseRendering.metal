//
//  WhirlNoiseRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/27/21.
//

#include <metal_stdlib>
using namespace metal;
#include "WhirlNoise.h"

[[kernel]]
void whirlNoiseRendering(uint2 tid                                  [[thread_position_in_grid]],
                         constant int & chunkSize                   [[buffer(0)]],
                         constant int & seed                        [[buffer(1)]],
                         constant float & z                         [[buffer(2)]],
                         constant bool & drawPoints                 [[buffer(3)]],
                         constant float & lightingX                 [[buffer(4)]],
                         constant float & lightingY                 [[buffer(5)]],
                         constant float & lightingZ                 [[buffer(6)]],
                         constant float & lightingIntensity         [[buffer(7)]],
                         texture2d<float, access::read_write> image [[texture(0)]]) {
    float3 coordinates = float3(float2(tid) - float2(image.get_width(), image.get_height()), z);
    float noise = whirlNoise(coordinates, float3(chunkSize), seed);
    if (drawPoints) {
        float3 point;
        float dist = INFINITY;
        for (int x = -1; x <= 1; x ++) {
            for (int y = -1; y <= 1; y ++) {
                for (int z = -1; z <= 1; z ++) {
                    float3 newPoint = chunkPoint(coordinates, int3(x, y, z), chunkSize, seed);
                    float newDist = distance(newPoint, coordinates);
                    if (newDist < dist) {
                        dist = newDist;
                        point = newPoint;
                    }
                }
            }
        }
        
        if (distance(coordinates, point) < float(chunkSize) / 8) {
            float4 lightingDirection = float4(-lightingX, -lightingY, -lightingZ, lightingIntensity);
            float3 color = float3(0, 0, 1);
            float3 normal = normalize(coordinates - point);
            float3 result = saturate(dot(normal, lightingDirection.xyz) * -1) * lightingDirection.w * color;
            image.write(float4(result, 1), tid);
            return;
        }
    }
    image.write(float4(float3(noise), 1), tid);
    
}

