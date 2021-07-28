//
//  SharedDataTypes.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/29/21.
//

#include <metal_stdlib>
using namespace metal;
#include "SharedDataTypes.h"

// TODO: Add spiral shiftedTid
// TODO: Add rotation
int computeCount(int2 imageSize, int2 computeSize) {
    int2 shift = int2(ceil(float2(imageSize)/float2(computeSize)));
    return shift.x * shift.y;
}

uint2 shiftedTid(uint2 tid,
                 int2 imageSize,
                 int2 computeSize,
                 int frame) {
    int2 shift = int2(ceil(float2(imageSize)/float2(computeSize)));
    frame = frame % (shift.x * shift.y);
    int x = frame % shift.x;
    int y = frame / shift.x;
    return uint2(x,y) * uint2(computeSize) + tid;
}

float3 randomColor(int seed) {
    float value = float(seed * 1282923947237 % 1352624);
    return abs(float3(cos(value),
                  sin(value),
                  cos(value) * sin(value)));
}

float lerp(float a, float b, float p) {
    return (b - a) * p + a;
}

float2 lerp(float2 a, float2 b, float p) {
    return (b - a) * p + a;
}

float3 lerp(float3 a, float3 b, float p) {
    return (b - a) * p + a;
}

float4 lerp(float4 a, float4 b, float p) {
    return (b - a) * p + a;
}

float hash(uint seed) {
    seed ^= 2747636419u;
    seed *= 2654435769u;
    seed ^= seed >> 16;
    seed *= 2654435769u;
    seed ^= seed >> 16;
    seed *= 2654435769u;
    return float(seed)/4294967295.0;
}

bool inImage(int2 position, int2 size) {
    return position.x >= 0 && position.y >= 0 && position.x < size.x && position.y < size.y;
}

bool inImage(int2 position, int2 shift, int2 size) {
    return inImage(position + shift, size);
}

bool inImage(uint2 position, int2 shift, int2 size) {
    return inImage(int2(position), shift, size);
}

float project(float3 base, float3 value) {
    return dot(base, value) / dot(base, base);
}

float project(float4 base, float4 value) {
    return dot(base, value) / dot(base, base);
}

float4 orthogonal(float4 base, float4 value) {
    return value - project(base, value);
}

float mod(float value, float cap) {
    return value - cap * float(int(value / cap));
}

float3 interpolateColors(constant float3 * colors, int colorCount, float percent) {
    if (percent >= 1) {
        return colors[colorCount-1];
    } else if (percent <= 0) {
        return colors[0];
    } else {
        // FIXME: I think this is wrong
        float value = percent * float(colorCount - 1);
        int minColor = value;
        float percentInRange = value - floor(value);
        return lerp(colors[minColor], colors[minColor + 1], percentInRange);
    }
}

float3 interpolateColors(float3 colors[], int colorCount, float percent) {
    if (percent >= 1) {
        return colors[colorCount-1];
    } else if (percent <= 0) {
        return colors[0];
    } else {
        // FIXME: I think this is wrong
        float value = percent * float(colorCount - 1);
        int minColor = value;
        float percentInRange = value - floor(value);
        return lerp(colors[minColor], colors[minColor + 1], percentInRange);
    }
}
