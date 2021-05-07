//
//  RenderPipeline.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/28/21.
//

#include <metal_stdlib>
using namespace metal;
#include "SharedDataTypes.h"

// Simple vertex shader which passes through NDC quad positions
vertex CopyVertexOut copyVertex(unsigned short vid [[vertex_id]]) {
    float2 position = quadVertices[vid];
    
    CopyVertexOut out;
    
    out.position = float4(position, 0, 1);
    out.uv = position * 0.5f + 0.5f;
    
    return out;
}

// Simple fragment shader which copies a texture and applies a simple tonemapping function
fragment float4 copyFragment(CopyVertexOut in [[stage_in]],
                             texture2d<float> tex)
{
    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
    
    float3 color = tex.sample(sam, in.uv).xyz;
    
    // Apply a very simple tonemapping function to reduce the dynamic range of the
    // input image into a range which can be displayed on screen.
//    color = color / (1.0f + color);
    
    return float4(color, 1.0f);
}

uint32_t createEntry(uint8_t red,
                 uint8_t green,
                 uint8_t blue,
                 uint8_t alpha) {
    return ((red) << 24) | ((green) << 16) | ((blue) << 8) | ((alpha) << 0);
}

uint8_t toInt(float value) {
    return int(value * 255);
}

kernel void encodeImage(uint2 tid [[thread_position_in_grid]],
                    device uint32_t * pixels [[buffer(0)]],
                    constant int & imageWidth [[buffer(1)]],
                    texture2d<float, access::read_write>Image) {
//    float4 value = Image.read(tid);
//    float4 value = float4(1,0,0,1);
//    pixels[tid.x + tid.y * imageWidth] = createEntry(toInt(value.x),
//                                                     toInt(value.y),
//                                                     toInt(value.z),
//                                                     toInt(value.w));
    pixels[tid.x + tid.y * imageWidth] = createEntry(0, 255, 0, 255);
}
