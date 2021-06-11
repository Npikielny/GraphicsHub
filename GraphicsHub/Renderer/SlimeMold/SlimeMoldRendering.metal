//
//  SlimeMoldRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/8/21.
//

#include <metal_stdlib>
using namespace metal;

struct Node {
    float2 position;
    float angle;
};

kernel void slimeMoldCalculate(uint tid [[thread_position_in_grid]],
                               device Node * nodeBuffer [[buffer(0)]],
                               constant int2 & imageSize [[buffer(1)]]) {
    
}

kernel void slimeMoldDraw(uint2 tid [[thread_position_in_grid]],
                          constant Node * nodeBuffer [[buffer(0)]],
                          texture2d<float, access::read_write> Image) {
    
}

