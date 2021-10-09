//
//  Shared.h
//  GraphicsHub
//
//  Created by Noah Pikielny on 9/7/21.
//

#ifndef Shared_h
#define Shared_h

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

int2 imageSize(metal::texture2d<float, metal::access::read_write> image);
int computeCount(int2 imageSize, int2 computeSize);
uint2 shiftedTid(uint2 tid,
                 int2 imageSize,
                 int2 computeSize,
                 int frame);
template<typename T>
T lerp(T a, T b, float p);
#endif /* Shared_h */
