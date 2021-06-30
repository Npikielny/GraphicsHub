//
//  AcceleratedRayTraceRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/27/21.
//

#include <metal_stdlib>
using namespace metal;
using namespace raytracing;

#include "../../Shared/SharedDataTypes.h"
#include "../Shared3D.h"

struct Intersection {
  float distance;
  int primitiveIndex;
  float2 coordinates;
};

struct PrimitiveRay {
  packed_float3 origin;
  uint mask;
  packed_float3 direction;
  float maxDistance;
  float3 color;
};

constant int TRIANGLE_MASK_GEOMETRY = 1;
constant int TRIANGLE_MASK_LIGHT = 2;

constant int RAY_MASK_PRIMARY = 3;
constant int RAY_MASK_SHADOW = 1;
constant int RAY_MASK_SECONDARY = 1;

[[kernel]]
void populateRays(uint2 tid [[thread_position_in_grid]],
                         device Ray * rays [[buffer(0)]],
                         constant int2 & imageSize [[buffer(1)]],
                         constant int2 & renderSize [[buffer(2)]],
                         constant float2 & randomDirection [[buffer(3)]],
                         constant float4x4 & modelMatrix [[buffer(4)]],
                         constant float4x4 & projectionMatrix [[buffer(5)]],
                         constant int & frame [[buffer(6)]]) {
    uint2 shiftTid = shiftedTid(tid, imageSize, renderSize, frame);
    rays[tid.x + tid.y * imageSize.x] = CreateCameraRay(uv(shiftTid, randomDirection, imageSize),
                                                        modelMatrix,
                                                        projectionMatrix);
    metal::raytracing::intersector<> x;
//    device PrimitiveRay & primitiveRay = rays[tid.x + tid.y * imageSize.x];
//    primitiveRay.origin = ray.origin;
//    primitiveRay.mask = RAY_MASK_PRIMARY;
//    primitiveRay.direction = ray.direction;
//    primitiveRay.maxDistance = INFINITY;
//    primitiveRay.color = float3(1);
}

//template<typename T>
//inline T interpolateVertexAttribute(device T *attributes, Intersection intersection) {
//  float3 uvw;
//  uvw.xy = intersection.coordinates;
//  uvw.z = 1.0f - uvw.x - uvw.y;
//  unsigned int triangleIndex = intersection.primitiveIndex;
//  T T0 = attributes[triangleIndex * 3 + 0];
//  T T1 = attributes[triangleIndex * 3 + 1];
//  T T2 = attributes[triangleIndex * 3 + 2];
//  return uvw.x * T0 + uvw.y * T1 + uvw.z * T2;
//}
//
//inline void sampleAreaLight(constant AreaLight & light,
//                            float2 u,
//                            float3 position,
//                            thread float3 & lightDirection,
//                            thread float3 & lightColor,
//                            thread float & lightDistance) {
//  u = u * 2.0f - 1.0f;
//  float3 samplePosition = light.position +
//  light.right * u.x +
//  light.up * u.y;
//  lightDirection = samplePosition - position;
//  lightDistance = length(lightDirection);
//  float inverseLightDistance = 1.0f / max(lightDistance, 1e-3f);
//  lightDirection *= inverseLightDistance;
//  lightColor = light.color;
//  lightColor *= (inverseLightDistance * inverseLightDistance);
//  lightColor *= saturate(dot(-lightDirection, light.forward));
//}
//
//inline float3 sampleCosineWeightedHemisphere(float2 u) {
//  float phi = 2.0f * M_PI_F * u.x;
//  float cos_phi;
//  float sin_phi = sincos(phi, cos_phi);
//  float cos_theta = sqrt(u.y);
//  float sin_theta = sqrt(1.0f - cos_theta * cos_theta);
//  return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
//}
//
//inline float3 alignHemisphereWithNormal(float3 sample, float3 normal) {
//  float3 up = normal;
//  float3 right = normalize(cross(normal, float3(0.0072f, 1.0f, 0.0034f)));
//  float3 forward = cross(right, up);
//  return sample.x * right + sample.y * up + sample.z * forward;
//}

//kernel void shadeKernel(uint2 tid [[thread_position_in_grid]],
//                        constant Uniforms & uniforms,
//                        device Ray *rays,
//                        device Ray *shadowRays,
//                        device Intersection *intersections,
//                        device float3 *vertexColors,
//                        device float3 *vertexNormals,
//                        device float2 *random,
//                        device uint *triangleMasks,
//                        texture2d<float, access::write> dstTex)
//{
//  if (tid.x < uniforms.width && tid.y < uniforms.height) {
//    unsigned int rayIdx = tid.y * uniforms.width + tid.x;
//    device Ray & ray = rays[rayIdx];
//    device Ray & shadowRay = shadowRays[rayIdx];
//    device Intersection & intersection = intersections[rayIdx];
//    float3 color = ray.color;
//    if (ray.maxDistance >= 0.0f && intersection.distance >= 0.0f) {
//      uint mask = triangleMasks[intersection.primitiveIndex];
//      if (mask == TRIANGLE_MASK_GEOMETRY) {
//        float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
//        float3 surfaceNormal = interpolateVertexAttribute(vertexNormals, intersection);
//        surfaceNormal = normalize(surfaceNormal);
//        float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
//        float3 lightDirection;
//        float3 lightColor;
//        float lightDistance;
//        sampleAreaLight(uniforms.light, r, intersectionPoint, lightDirection,
//                        lightColor, lightDistance);
//        lightColor *= saturate(dot(surfaceNormal, lightDirection));
//        color *= interpolateVertexAttribute(vertexColors, intersection);
//        shadowRay.origin = intersectionPoint + surfaceNormal * 1e-3f;
//        shadowRay.direction = lightDirection;
//        shadowRay.mask = RAY_MASK_SHADOW;
//        shadowRay.maxDistance = lightDistance - 1e-3f;
//        shadowRay.color = lightColor * color;
//        float3 sampleDirection = sampleCosineWeightedHemisphere(r);
//        sampleDirection = alignHemisphereWithNormal(sampleDirection, surfaceNormal);
//        ray.origin = intersectionPoint + surfaceNormal * 1e-3f;
//        ray.direction = sampleDirection;
//        ray.color = color;
//        ray.mask = RAY_MASK_SECONDARY;
//      }
//      else {
//        dstTex.write(float4(uniforms.light.color, 1.0f), tid);
//        ray.maxDistance = -1.0f;
//        shadowRay.maxDistance = -1.0f;
//      }
//    }
//    else {
//      ray.maxDistance = -1.0f;
//      shadowRay.maxDistance = -1.0f;
//    }
//  }
//}

kernel void shadeRays(uint2 tid [[ thread_position_in_grid ]],
                      constant PrimitiveRay * rays [[ buffer(0) ]],
                      constant int2 & imageSize [[ buffer(1) ]],
                      constant int2 & computeSize [[ buffer(2) ]],
                      constant int & frame [[ buffer(3) ]],
                      device PrimitiveRay *shadowRays,
                      device Intersection *intersections,
                      device float3 *vertexColors,
                      device float3 *vertexNormals,
                      device float2 *random,
                      device uint *triangleMasks,
                      texture2d<float>sky) {
    
}

//kernel void shadowKernel(uint2 tid [[thread_position_in_grid]],
//                         constant Uniforms & uniforms,
//                         device Ray *shadowRays,
//                         device float *intersections,
//                         texture2d<float, access::read_write> dstTex)
//{
//  if (tid.x < uniforms.width && tid.y < uniforms.height) {
//    unsigned int rayIdx = tid.y * uniforms.width + tid.x;
//    device Ray & shadowRay = shadowRays[rayIdx];
//    float intersectionDistance = intersections[rayIdx];
//    if (shadowRay.maxDistance >= 0.0f && intersectionDistance < 0.0f) {
//      float3 color = shadowRay.color;
//      color += dstTex.read(tid).xyz;
//      dstTex.write(float4(color, 1.0f), tid);
//    }
//  }
//}

kernel void shadowRays(uint2 tid [[ thread_position_in_grid ]]) {}

kernel void copyRaysToTexture(uint2 tid [[thread_position_in_grid]],
                              constant Ray * rays [[ buffer(0) ]],
                              constant int2 & imageSize [[ buffer(1) ]],
                              constant int2 & computeSize [[ buffer(2) ]],
                              constant int & frame [[ buffer(3) ]],
                              texture2d<float, access::write> Image [[texture(0)]]) {
    uint2 shiftTid = shiftedTid(tid, imageSize, computeSize, frame);
//    Image.write(float4(rays[tid.x + tid.y * imageSize.x].color, 1), shiftTid);
    Image.write(float4(float3(0), 1), shiftTid);
}
