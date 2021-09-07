//
//  TestRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 9/7/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Shared.h"
fragment float4 uvFragment(CopyVertexOut in       [[ stage_in   ]],
                             texture2d<float> tex [[ texture(0) ]]) {
    return float4(in.uv, 0, 1);
}
