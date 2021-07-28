//
//  WhirlNoise.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/27/21.
//

#include <metal_stdlib>
using namespace metal;
#include "WhirlNoise.h"
#include "../Shared/SharedDataTypes.h"

float3 chunkPoint(float3 coordinates, int3 chunkOffset, float3 chunkSize, int seed) {
    int3 direction = int3(sign(coordinates.x), sign(coordinates.y), sign(coordinates.z));
    int3 chunk = int3(abs(coordinates) / chunkSize) * direction + chunkOffset;
    seed = chunk.x * seed * 6849846516 +  chunk.y * seed * 13568745636 +  chunk.z * seed * 5485486754;
    float3 seedOffset = float3(hash(seed),
                               hash(seed),
                               hash(seed));
    return float3(chunk) * chunkSize + chunkSize * seedOffset * float3(direction);
}

float whirlNoise(float3 coordinates, float3 chunkSize, int seed) {
    float dist = INFINITY;
    for (int x = -1; x <= 1; x ++) {
        for (int y = -1; y <= 1; y ++) {
            for (int z = -1; z <= 1; z ++) {
                float currentDistance = clamp(distance(coordinates,
                                                 chunkPoint(coordinates, int3(x, y, z), chunkSize, seed)) / length(chunkSize), 0.0, 1.0);
                dist = min(dist, currentDistance);
            }
        }
    }
    return (1 - dist);
}
