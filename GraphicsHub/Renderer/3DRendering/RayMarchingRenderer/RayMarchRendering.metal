//
//  RayMarchRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/13/21.
//

#include <metal_stdlib>
using namespace metal;

#include <metal_stdlib>
using namespace metal;
#include "../../Shared/SharedDataTypes.h"
#include "../Shared3D.h"

float GroundPlaneDistance(float3 origin) {
    return origin.y;
}

float SphereDistance(float3 origin, Object object) {
    return distance(origin, object.position) - object.size.x;
}

float BoxDistance(float3 ray, Object Box) {
    
    float3x3 Rx = float3x3(float3(1, 0, 0),
                           float3(0, cos(-Box.rotation.x), -1 * sin(-Box.rotation.x)),
                           float3(0, sin(-Box.rotation.x), cos(-Box.rotation.x)));
    float3x3 Ry = float3x3(float3(cos(-Box.rotation.y), 0, sin(-Box.rotation.y)),
                           float3(0, 1, 0),
                           float3(-sin(-Box.rotation.y), 0, cos(-Box.rotation.y)));
    float3x3 Rz = float3x3(float3(cos(-Box.rotation.z), -sin(-Box.rotation.z), 0),
                           float3(sin(-Box.rotation.z), cos(-Box.rotation.z), 0),
                           float3(0, 0, 1));
    float3x3 RotationMatrix = Rx * Ry * Rz;
    float3 rotatedPoint = ((ray-Box.position) * RotationMatrix);
    
    float3 q = abs(rotatedPoint) - Box.size;
    
    return length(max(q, 0) + min(max3(q.x, q.y, q.z), 0.0));
}

float TorusDistance(float3 ray, Object Torus)
{
    float2 q = float2(length((ray - Torus.position).xz) - Torus.size.x, ray.y - Torus.position.y);
    return length(q) - Torus.size.y;
}

float PrismDistance(float3 ray, Object Prism) {
    float3 q = abs(ray - Prism.position);
    return max(q.z - Prism.size.y,max(q.x * 0.866025+ray.y*0.5,-ray.y) - Prism.size.x * 0.5);
}

float CylinderDistance(float3 ray, Object Cylinder) {
    float2 d = abs(float2(length((ray - Cylinder.position).xz), ray.y)) - Cylinder.size.xy;
    return length(max(d, 0.0)) + max(min(d.x, 0.0),min(d. y, 0.0));
}

float getDistance(float3 origin, Object object) {
    if (object.objectType == sphere) {
        return SphereDistance(origin, object);
    } else if (object.objectType == box) {
        return BoxDistance(origin, object);
    } else if (object.objectType == groundPlane) {
        return GroundPlaneDistance(origin);
    }else if (object.objectType == Torus) {
        return TorusDistance(origin, object);
    } else if (object.objectType == prism) {
        return PrismDistance(origin, object);
    } else if (object.objectType == cylinder) {
        return CylinderDistance(origin, object);
    } else {
        return INFINITY;
    }
}

constant Object GroundPlane = createObject(groundPlane,
                                           float3(0),
                                           float3(0),
                                           float3(0),
                                           createMaterial(float3(0.7, 0.2, 0.2),
                                                          float3(0.7, 0.2, 0.2),
                                                          1,
                                                          1,
                                                          float3(0)));

float SDF(Ray ray, constant Object * objects, int objectCount, thread Object & object, bool groundPlane) {
    if (groundPlane) {
        object = GroundPlane;
    }
    float minDist = groundPlane ? GroundPlaneDistance(ray.origin) : INFINITY;
    for (int i = 0; i < objectCount; i ++) {
        float dist = getDistance(ray.origin, objects[i]);
        if (dist < minDist) {
            minDist = dist;
            object = objects[i];
        }
    }
    return minDist;
}

float3 estimateNormal (float3 ray, Object object, float precision) {
    return normalize(float3(getDistance(ray + float3(precision, 0, 0), object) - getDistance(ray - float3(precision, 0, 0), object),
                            getDistance(ray + float3(0, precision, 0), object) - getDistance(ray - float3(0, precision, 0), object),
                            getDistance(ray + float3(0, 0, precision), object) - getDistance(ray - float3(0, 0, precision), object)));
}


float3 getNormal(float3 origin, Object object, float precision) {
//    if (object.objectType == sphere) {
//        return normalize(origin - object.position);
//    } else {
        return estimateNormal(origin, object, precision);
//    }
}

kernel void rayMarch (uint2 tid [[thread_position_in_grid]],
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
                      constant int & maxIterations [[buffer(10)]],
                      constant float & maxDistance [[buffer(11)]],
                      constant float & precision [[buffer(12)]],
                      texture2d<float> sky [[texture(0)]],
                      texture2d<float, access::read_write>image [[texture(1)]]) {
    tid = shiftedTid(tid, imageSize, raySize, frame);
    if (int(tid.x) > imageSize.x || int(tid.y) > imageSize.y) { return; }
    
    float4x4 modelMatrix = cameraMatrices[0];
    float4x4 projectionMatrix = cameraMatrices[1];
    
    thread Object && object = Object();
    Ray ray = CreateCameraRay(uv(tid, randomDirection, imageSize),
                              modelMatrix,
                              projectionMatrix);
    int iterations = 0;
    float dist = 0;
    while (iterations < maxIterations && dist < maxDistance) {
        iterations += 1;
        dist = SDF(ray, objects, objectCount, object, false);
        if (dist < precision) {
            float3 normal = getNormal(ray.origin + ray.direction * (dist - precision), object, precision);
            float3 result = saturate(dot(normal, lightingDirection.xyz) * -1) * lightingDirection.w * object.material.albedo * (1 - object.material.specular) + object.material.specular * sky.read(sampleSky(reflect(ray.direction, normal), skySize)).xyz;
            image.write(float4(result, 1), tid);
            return;
        }
        ray.origin += ray.direction * dist;
    }
    image.write(float4(sky.read(sampleSky(ray.direction, skySize)).xyz, 1), tid);
}
