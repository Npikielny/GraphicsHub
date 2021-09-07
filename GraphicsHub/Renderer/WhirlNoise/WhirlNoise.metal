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

int signedInt(float value) {
    if (value >= 0 || fract(value) == 0) {
        return int(value);
    } else {
        return int(value) - 1;
    }
}

int3 signedInt(float3 value) {
    return int3(signedInt(value.x),
                signedInt(value.y),
                signedInt(value.z));
}

float3 chunkPoint(float3 coordinates, int3 chunkOffset, float3 chunkSize, int seed, float density) {
    int3 chunk = signedInt(coordinates / chunkSize) + chunkOffset;
    seed = chunk.x * seed * 6849846516 + chunk.y * seed * 13568745636 +  chunk.z * seed * 5485486754;
    if (hash(seed) > density) { return float3(INFINITY); }
    float3 seedOffset = float3(hash(seed * 148463545),
                               hash(seed * 456546536),
                               hash(seed * 846546513));
    return float3(chunk) * chunkSize + chunkSize * seedOffset;// * float3(direction);
}

float3 whirlNormal(float3 coordinates, float3 chunkSize, int seed) {
    float dist = INFINITY;
    float3 normal = float3(0, 1, 0);
    for (int x = -1; x <= 1; x ++) {
        for (int y = -1; y <= 1; y ++) {
            for (int z = -1; z <= 1; z ++) {
                float3 point = chunkPoint(coordinates, int3(x, y, z), chunkSize, seed, 1);
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

float whirlNoise(float3 coordinates, float3 chunkSize, int seed, float scaling, float density) {
    float dist = INFINITY;
    for (int x = -1; x <= 1; x ++) {
        for (int y = -1; y <= 1; y ++) {
            for (int z = -1; z <= 1; z ++) {
                float currentDistance = clamp(distance(coordinates,
                                                 chunkPoint(coordinates, int3(x, y, z), chunkSize, seed, density)) / length(chunkSize * (1 + scaling)), 0.0, 1.0);
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
                                                 chunkPoint(coordinates, int3(x, y, z), chunkSize, seed, 1)) / length(chunkSize), 0.0, 1.0);
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

float3 smoothWhirlNormal(float3 coordinates, float3 chunkSize, int seed, float blendingStrength, float precision) {
    return normalize(float3(
                            smoothWhirlNoise(coordinates + float3(precision, 0, 0), chunkSize, seed, blendingStrength) - smoothWhirlNoise(coordinates - float3(precision, 0, 0), chunkSize, seed, blendingStrength),
                            smoothWhirlNoise(coordinates + float3(0, precision, 0), chunkSize, seed, blendingStrength) - smoothWhirlNoise(coordinates - float3(0, precision, 0), chunkSize, seed, blendingStrength),
                            smoothWhirlNoise(coordinates + float3(0, 0, precision), chunkSize, seed, blendingStrength) - smoothWhirlNoise(coordinates - float3(0, 0, precision), chunkSize, seed, blendingStrength)
                            )
                     );
}

    
float whirlNoise(float3 coordinates, float3 chunkSize[], int seed[], float scaling[], float density[], int iterations) {
    float value = 0;
    for (int i = 0; i < iterations; i++) {
        value += whirlNoise(coordinates, chunkSize[i], seed[i], scaling[i], density[i]) / pow(2.0, float(i + 1));
    }
    return value;
}

float recursiveWhirlNoise(float3 coordinates, float3 chunkSize, float chunkFactor, int seed, float scaling, float scalingFactor, float density, float densityFactor, int iterations) {
    float value = 0;
    for (int i = 0; i < iterations; i++) {
        value += whirlNoise(coordinates, chunkSize, seed, scaling, density) / pow(2.0, float(i + 1));
        chunkSize *= chunkFactor;
        seed = int(hash(seed) * 92382093582032);
        scaling *= scalingFactor;
        density *= densityFactor;
    }
    return value;
}
float recursiveSample(float3 origin, float3 direction, float length, int iteration, float chunkFactor, int seed, float scaling, float scalingFactor, float density, float densityFactor, int iterations) {
    float total = 0;
    if (length == 0) { return 0; }
    for (int i = 0; i < iterations; i ++) {
        total += recursiveWhirlNoise(origin + direction * float(i) / float(iterations) * length, float3(300), 0.5, 2030952038, 0.5, 0.5, 0.5, 1, 3);
    }
    return total;
}
