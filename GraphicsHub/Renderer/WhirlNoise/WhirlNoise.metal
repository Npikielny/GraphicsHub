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

float3 whirlNormal(float3 coordinates, float3 chunkSize, int seed) {
    float dist = INFINITY;
    float3 normal = float3(0, 1, 0);
    for (int x = -1; x <= 1; x ++) {
        for (int y = -1; y <= 1; y ++) {
            for (int z = -1; z <= 1; z ++) {
                float3 point = chunkPoint(coordinates, int3(x, y, z), chunkSize, seed);
                float currentDistance = clamp(distance(coordinates,
                                                 point) / length(chunkSize), 0.0, 1.0);
                if (currentDistance < dist) {
                    dist = currentDistance;
                    normal = normalize(coordinates - point);
                }
            }
        }
    }
    
    return normal;
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

// Polynomial smooth minimum by iq
float3 smin(float3 a, float3 b, float k) {
  float3 h = clamp(0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
  return mix(a, b, h) - k * h * (1.0 - h);
}

float3 smoothWhirlNormal(float3 coordinates, float3 chunkSize, int seed, float blendingStrength) {
    float3 normal = float3(0, 0, 0);
    for (int x = -1; x <= 1; x ++) {
        for (int y = -1; y <= 1; y ++) {
            for (int z = -1; z <= 1; z ++) {
                float3 point = chunkPoint(coordinates, int3(x, y, z), chunkSize, seed);
                float currentDistance = clamp(distance(coordinates,
                                                 point) / length(chunkSize), 0.0, 1.0);
                if (length(normal) == 0) {
                    normal = -coordinates + point;
                } else {
                    normal = smin(normal, -coordinates + point, blendingStrength);
                }
            }
        }
    }
    
    return normalize(-normal);
}

// Polynomial smooth minimum by iq
float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
  return mix(a, b, h) - k * h * (1.0 - h);
}

float smoothWhirlNoise(float3 coordinates, float3 chunkSize, int seed, float blendingStrength) {
    float dist = INFINITY;
    for (int x = -1; x <= 1; x ++) {
        for (int y = -1; y <= 1; y ++) {
            for (int z = -1; z <= 1; z ++) {
                float currentDistance = clamp(distance(coordinates,
                                                 chunkPoint(coordinates, int3(x, y, z), chunkSize, seed)) / length(chunkSize), 0.0, 1.0);
//                dist = min(dist, currentDistance);
                if (dist == INFINITY) {
                    dist = currentDistance;
                } else {
                    dist = smin(dist, currentDistance, blendingStrength);
                }
            }
        }
    }
    return (1 - dist);
}
