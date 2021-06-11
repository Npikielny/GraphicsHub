//
//  TesterPipeline.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../Renderer/Shared/SharedDataTypes.h"

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
int requiredFrames(int2 imageSize,
                   int2 computeSize) {
    int2 shift = int2(ceil(float2(imageSize)/float2(computeSize)));
    return shift.x * shift.y;
}

kernel void testerSinglyCapped(uint2    tid                               [[thread_position_in_grid]],
                               constant int  & frame                      [[buffer(0)]],
                               constant int2 & imageSize                  [[buffer(1)]],
                               constant int2 & computeSize                [[buffer(2)]],
                               constant int  & seed                       [[buffer(3)]],
                               texture2d<float, access::read_write>image [[texture(0)]]) {
    tid = shiftedTid(tid, imageSize, computeSize, frame);
    
    
    float2 percents = float2(tid) / float2(imageSize);
    float3 zeroColor = randomColor(seed);
    float3 xColor = lerp(zeroColor, randomColor(seed * 3 + 1), percents.x);
    float3 yColor = lerp(zeroColor, randomColor(seed * 7), percents.y);
    
    image.write(float4((xColor + yColor) / 2,1), tid);
    
}
