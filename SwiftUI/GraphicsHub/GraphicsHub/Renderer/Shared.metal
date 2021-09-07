//
//  Shared.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 9/7/21.
//

#include <metal_stdlib>
#include "Shared.h"
using namespace metal;
// MARK: Image helpers
int2 imageSize(texture2d<float, access::read_write> image) {
    return int2(image.get_width(), image.get_height());
}

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

template<typename T>
T lerp(T a, T b, float p) {
    return (b - a) * p + a;
}
