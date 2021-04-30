//
//  TesterPipeline.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../Renderer/SharedDataTypes.h"

// Simple fragment shader which copies a texture and applies a simple tonemapping function
fragment float4 testerFragment(CopyVertexOut in [[stage_in]],
                             texture2d<float> tex)
{
    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
    
    float3 color = tex.sample(sam, in.uv).xyz;
    
    // Apply a very simple tonemapping function to reduce the dynamic range of the
    // input image into a range which can be displayed on screen.
    color = float3(in.uv,0);
    return float4(color, 1.0f);
}

uint2 shiftedTid2(uint2 tid,
                 int2 imageSize,
                 int2 computeSize,
                 int frame) {
    int2 shift = int2(ceil(float2(imageSize)/float2(computeSize)));
    frame = frame - shift.x * shift.y;
    int x = frame % shift.x;
    int y = frame / shift.x;
    return uint2(x,y) * uint2(computeSize) + tid;
}

float3 randomColor2(int seed) {
    float value = float(seed);
    return abs(float3(cos(value * 13 + 64),
                  sin(value * 4 + 2),
                  cos(value * 31) * sin(value * 15)));
}

float lerp2(float a, float b, float p) {
    return (b - a) * p + a;
}

float2 lerp2(float2 a, float2 b, float p) {
    return (b - a) * p + a;
}

float3 lerp2(float3 a, float3 b, float p) {
    return (b - a) * p + a;
}

float4 lerp2(float4 a, float4 b, float p) {
    return (b - a) * p + a;
}

//uint2 shiftTid (uint2 tid, int2 textureSize, int2 raySize, int frame) {
//
//    int2 maxSize = textureSize/raySize + int2(1,1);
//    //Chunks
//    int x = ((frame) % maxSize.x) * raySize.x;
//    int y = ((frame*raySize.x / (textureSize.x+raySize.x)) % maxSize.y) * raySize.y;
//    //Distribution
////    int x = ((frame+tid.x) % maxSize.x)*raySize.x;
////    int y = ((frame*raySize.x / (textureSize.x+raySize.x)+tid.y) % maxSize.y) * raySize.y;
//    return tid + uint2(x,y);
//
//}

int requiredFrames(int2 imageSize,
                   int2 computeSize) {
    int2 shift = int2(ceil(float2(imageSize)/float2(computeSize)));
    return shift.x * shift.y;
}

kernel void testerSinglyCapped(uint2 tid [[thread_position_in_grid]],
                               constant int &frame                        [[buffer(0)]],
                               constant int2 &imageSize                   [[buffer(1)]],
                               constant int2 &computeSize                 [[buffer(2)]],
                               texture2d<float, access::read_write>image [[texture(0)]]) {
    tid = shiftedTid(tid, imageSize, computeSize, frame);
    
    
    float2 percents = float2(tid) / float2(imageSize);
    int seed = frame / requiredFrames(imageSize, computeSize);
    float3 zeroColor = randomColor2(seed);
    float3 xColor = lerp2(zeroColor, randomColor2(seed * 3 + 1), percents.x);
    float3 yColor = lerp2(zeroColor, randomColor2(seed * 7), percents.y);
    
    image.write(float4((xColor + yColor) / 2,1), tid);
    
}
