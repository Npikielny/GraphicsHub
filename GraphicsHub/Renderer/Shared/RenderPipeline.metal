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

struct Pixel {
    uint32_t color;
};

// Simple fragment shader which copies a texture and applies a simple tonemapping function
fragment float4 copyFragment(CopyVertexOut in [[stage_in]],
                             texture2d<float> tex)
{
    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
    
    float4 color = tex.sample(sam, in.uv);
    
    // Apply a very simple tonemapping function to reduce the dynamic range of the
    // input image into a range which can be displayed on screen.
//    color = color / (1.0f + color);
    
    return color;
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

uint32_t createEntry(float4 color) {
    return createEntry(toInt(color.x),
                       toInt(color.y),
                       toInt(color.z),
                       toInt(color.w));
}

uint8_t redComponent (uint32_t color) {
    return ((color >> 24) & 255);
}

uint8_t greenComponent (uint32_t color) {
    return ((color >> 16) & 255);
}

uint8_t blueComponent (uint32_t color) {
    return ((color >> 8) & 255);
}

uint8_t alphaComponent(uint32_t color) {
    return ((color >> 0) & 255);
}

kernel void encodeImage(uint2 tid [[thread_position_in_grid]],
                    device Pixel * pixels [[buffer(0)]],
                    constant int & imageWidth [[buffer(1)]],
                    constant int & imageHeight [[buffer(2)]],
                    texture2d<float, access::read_write>Image) {
    float4 value = Image.read(uint2(tid.x,tid.y));
    pixels[tid.x + (imageHeight-tid.y) * imageWidth].color = createEntry(value);
}

kernel void averageImages(uint2 tid [[thread_position_in_grid]],
                    constant int & frames [[buffer(0)]],
                    texture2d<float, access::read_write> current,
                    texture2d<float, access::read_write> previous) {
    current.write((current.read(tid) + float(frames - 1) * previous.read(tid))/(float(frames)), tid);
}

// Simple fragment shader which copies a texture and applies a simple tonemapping function
fragment float4 cappedCopyFragment(CopyVertexOut in [[stage_in]],
                             texture2d<float> tex1,
                             texture2d<float>tex2)
{
    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);
    
    float4 color1 = tex1.sample(sam, in.uv);
    float4 color2 = tex2.sample(sam, in.uv);
    
    // Apply a very simple tonemapping function to reduce the dynamic range of the
    // input image into a range which can be displayed on screen.
//    color = color / (1.0f + color);
    
    return (color1 + color2) / 2;
}
