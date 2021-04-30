//
//  ComplexRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/30/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../Renderer/SharedDataTypes.h"

float3 complexColor(constant float3 * colors, int colorCount, float percent) {
    if (percent >= 1) {
        return colors[colorCount - 1];
    }else if (percent <= 0) {
        return colors[0];
    }else {
        int minColorIndex = int(percent * float(colorCount));
        return lerp(colors[minColorIndex],colors[minColorIndex+1],percent);
    }
}

float2 multiplyImaginary(float2 im1, float2 im2) {
    float real = im1.x * im2.x - im1.y * im2.y;
    float imaginary = im1.x * im2.y + im1.y * im2.x;
    return float2(real, imaginary);
}

kernel void juliaSet(uint2 tid [[thread_position_in_grid]],
                     constant int2 & imageSize [[buffer(0)]],
                     constant int2 & renderSize [[buffer(1)]],
                     constant int & frame [[buffer(2)]],
                     constant float2 & origin [[buffer(3)]],
                     constant float2 & c [[buffer(4)]],
                     constant float & zoom [[buffer(5)]],
                     constant float3 * colors [[buffer(6)]],
                     constant int & colorCount [[buffer(7)]],
                     texture2d<float, access::read_write>Image) {
    tid = shiftedTid(tid, imageSize, renderSize, frame);
    float2 z = (float2(tid.x,tid.y) - float2(imageSize)/2) / zoom + origin;
    int value = 0;
    for (int i = 0; i < 255; i ++) {
        z = multiplyImaginary(z, z);
        z = float2(z.x+c.x,z.y+c.y);
        if (pow(z.x*z.x+z.y*z.y,0.5) > 4) {
            value = i;
        }
    }
    Image.write(float4(complexColor(colors, colorCount, float(value) / 255 * 5), 1), tid);
//    Image.write(float4(1) * float(value) / 255, tid);
}

kernel void mandelbrotSet() {}
