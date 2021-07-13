//
//  VanillaRayTraceRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/16/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Shared/SharedDataTypes.h"
#include "../Shared3D.h"

kernel void rayTrace (uint2 tid [[thread_position_in_grid]],
                      constant Object * objects [[buffer(0)]],
                      constant int & objectCount [[buffer(1)]],
                      constant float4x4 * cameraMatrices [[buffer(2)]],
                      constant int2 & imageSize [[buffer(3)]],
                      constant int2 & raySize [[buffer(4)]],
                      constant int2 & skySize [[buffer(5)]],
                      constant float4 & lightingDirection [[buffer(6)]],
                      constant float2 & randomDirection [[buffer(7)]],
                      constant float & skyIntensity [[buffer(8)]],
                      constant int & frame [[buffer(9)]],
                      texture2d<float> sky [[texture(0)]],
                      texture2d<float, access::read_write>image [[texture(1)]]){
    
    float4x4 modelMatrix = cameraMatrices[0];
    float4x4 projectionMatrix = cameraMatrices[1];
    
    tid = shiftedTid(tid, imageSize, raySize, frame);
    if (int(tid.x) < imageSize.x && int(tid.y) < imageSize.y) {
        thread Ray &&ray = CreateCameraRay(uv(tid, randomDirection, imageSize),
                                           modelMatrix,
                                           projectionMatrix);

        float3 result = float3(0, 0, 0);
        for (int i = 0; i < 8; i++) {
            RayHit hit = Trace(ray, objectCount, objects, true);
            result += ray.energy * Shade(ray, hit, sky, skySize, objectCount, objects, lightingDirection, skyIntensity);
            if (length(ray.energy) == 0) {
                break;
            }
        }
        
        // FIXME: Why is this necessary?
        result = clamp(result, float3(0), float3(1));
        image.write(float4(result,1), tid);
        return;
    }
}
