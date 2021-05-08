//
//  SharedDataTypes.h
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

#ifndef SharedDataTypes_h
#define SharedDataTypes_h
// Screen filling quad in normalized device coordinates
constant float2 quadVertices[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

struct CopyVertexOut {
    float4 position [[position]];
    float2 uv;
};

uint2 shiftedTid(uint2 tid,
                 int2 imageSize,
                 int2 computeSize,
                 int frame);

float3 randomColor(int seed);

float lerp(float a, float b, float p);

float2 lerp(float2 a, float2 b, float p);

float3 lerp(float3 a, float3 b, float p);

float4 lerp(float4 a, float4 b, float p);

float hash(uint seed);
#endif /* SharedDataTypes_h */
