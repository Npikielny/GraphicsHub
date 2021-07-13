//
//  PathTraceRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/27/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../../Shared/SharedDataTypes.h"
#include "../Shared3D.h"

inline float3 sampleCosineWeightedHemisphere(float2 u) {
    float phi = 2.0f * M_PI_F * u.x;

    float cos_phi;
    float sin_phi = sincos(phi, cos_phi);

    float cos_theta = sqrt(u.y);
    float sin_theta = sqrt(1.0f - cos_theta * cos_theta);

    return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
}

// Aligns a direction on the unit hemisphere such that the hemisphere's "up" direction
// (0, 1, 0) maps to the given surface normal direction.
inline float3 alignHemisphereWithNormal(float3 sample, float3 normal) {
    // Set the "up" vector to the normal
    float3 up = normal;

    // Find an arbitrary direction perpendicular to the normal. This will become the
    // "right" vector.
    float3 right = normalize(cross(normal, float3(0.0072f, 1.0f, 0.0034f)));

    // Find a third vector perpendicular to the previous two. This will be the
    // "forward" vector.
    float3 forward = cross(right, up);

    // Map the direction on the unit hemisphere to the coordinate system aligned
    // with the normal.
    return sample.x * right + sample.y * up + sample.z * forward;
}

float sdot(float3 x, float3 y, float f = 1.0f) {
    return saturate(dot(x, y) * f);
}

float energy(float3 color) {
    return dot(color, 1.0f / 3.0f);
}

float3x3 GetTangentSpace(float3 normal)
{
    // Choose a helper vector for the cross product
    float3 helper = float3(1, 0, 0);
    if (abs(normal.x) > 0.99f)
        helper = float3(0, 0, 1);
    // Generate vectors
    float3 tangent = normalize(cross(normal, helper));
    float3 binormal = normalize(cross(normal, tangent));
    return float3x3(tangent, binormal, normal);
}

float3 SampleHemisphere(float3 normal, float alpha, float2 r)
{
    // Sample the hemisphere, where alpha determines the kind of the sampling
    float cosTheta = pow(r.x, 1.0f / (alpha + 1.0f));
    float sinTheta = sqrt(1.0f - cosTheta * cosTheta);
    float phi = 2 * M_PI_F * r.y;
    float3 tangentSpaceDir = float3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
    // Transform direction to world space
    return tangentSpaceDir;// * GetTangentSpace(normal);
}

float SmoothnessToPhongAlpha(float s) {
    return pow(1000.0f, s * s);
}


float3 PathShade(thread Ray &ray, RayHit hit, texture2d<float> sky, int2 skyDimensions, int sphereCount, constant Object * objects, float4 lightDirection, float skyIntensity, float2 r, float roulette) {
    
   if (hit.distance < INFINITY) {
       // Calculate chances of diffuse and specular reflection
       hit.material.albedo = min(1.0f - hit.material.specular, hit.material.albedo);
       float specChance = energy(hit.material.specular);
       float diffChance = energy(hit.material.albedo);
       float sum = specChance + diffChance;
       specChance /= sum;
       diffChance /= sum;
       // Roulette-select the ray's path
       float roulette = r.x;
       if (roulette < specChance)
       {
           // Specular reflection
           ray.origin = hit.position + hit.normal * 0.001f;
           ray.direction = reflect(ray.direction, hit.normal);
           ray.energy *= (1.0f / specChance) * hit.material.specular * sdot(hit.normal, ray.direction);
       }
       else
       {
           // Diffuse reflection
           ray.origin = hit.position + hit.normal * 0.001f;
           ray.direction = ray.direction = alignHemisphereWithNormal(sampleCosineWeightedHemisphere(r), hit.normal);;
           ray.energy *= (1.0f / diffChance) * 2 * hit.material.albedo * sdot(hit.normal, ray.direction);
       }
       return 0.0f;
       
//
//       // Calculate chances of diffuse and specular reflection
//       hit.material.albedo = min(1.0f - hit.material.specular, hit.material.albedo);
//       float specChance = energy(hit.material.specular);
//       float diffChance = energy(hit.material.albedo);
//       float sum = specChance + diffChance;
//       specChance /= sum;
//       diffChance /= sum;
//       // Roulette-select the ray's path
//       if (roulette < specChance) {
//           // Specular reflection
//           float alpha = 15.0f;
//           ray.origin = hit.position + hit.normal * 0.001f;
////           ray.direction = alignHemisphereWithNormal(sampleCosineWeightedHemisphere(r), reflect(ray.direction, hit.normal));
////           ray.direction = alignHemisphereWithNormal(SampleHemisphere(hit.normal, alpha, r), hit.normal);
//           ray.direction = SampleHemisphere(reflect(ray.direction, hit.normal), alpha, r);
//           float f = (alpha + 2) / (alpha + 1);
//           ray.energy *= (1.0f / specChance) * hit.material.specular * sdot(hit.normal, ray.direction, f);
//       } else if (diffChance > 0 && roulette < specChance + diffChance) {
//           // Diffuse reflection
//           ray.origin = hit.position + hit.normal * 0.001f;
////           ray.direction = SampleHemisphere(hit.normal, 1.0f, r);
////           ray.direction = alignHemisphereWithNormal(SampleHemisphere(hit.normal, 1, r), hit.normal);
//           ray.direction = alignHemisphereWithNormal(sampleCosineWeightedHemisphere(r), hit.normal);
//           ray.energy *= (1.0f / diffChance) * hit.material.albedo;
//       } else {
//           ray.energy = 0;
//       }
//       return 0;
   }else {
       // Sample the skybox and write it
       ray.energy = float3(0);
       return sky.read(sampleSky(ray.direction, skyDimensions)).xyz * skyIntensity;
   }
}

kernel void pathTrace (uint2 tid [[thread_position_in_grid]],
                       constant Object * objects [[buffer(0)]],
                       constant int & objectCount [[buffer(1)]],
                       constant float4x4 * cameraMatrices [[buffer(2)]],
                       constant int2 & imageSize [[buffer(3)]],
                       constant int2 & raySize [[buffer(4)]],
                       constant int2 & skySize [[buffer(5)]],
                       constant float4 & lightingDirection [[buffer(6)]],
                       constant float2 & randomDirection [[buffer(7)]],
                       constant int & intermediateFrame [[buffer(8)]],
                       constant int & passes [[buffer(9)]],
                       constant int & passesPerFrame [[buffer(10)]],
                       constant int & frame [[buffer(11)]],
                       constant float & skyIntensity [[buffer(12)]],
                       texture2d<float> sky [[texture(0)]],
                       texture2d<float, access::read_write>image [[texture(1)]]){
    
    float4x4 modelMatrix = cameraMatrices[0];
    float4x4 projectionMatrix = cameraMatrices[1];

    tid = shiftedTid(tid, imageSize, raySize, intermediateFrame);
    if (int(tid.x) < imageSize.x && int(tid.y) < imageSize.y) {
        float2 uv = float2((float2(tid) + randomDirection / 2 + float2(0.5f, 0.5f)) / float2(imageSize.x, imageSize.y) * 2.0f - 1.0f);
        thread Ray &&ray = CreateCameraRay(uv, modelMatrix, projectionMatrix);

        int countPerFrame = computeCount(imageSize, raySize);
        int passed = countPerFrame * passesPerFrame * frame + countPerFrame * passes + intermediateFrame;
        
        float3 result = float3(0, 0, 0);
        
        for (int bounce = 0; bounce < 8; bounce++) {
            RayHit hit = Trace(ray, objectCount, objects, true);
//            RayHit hit = Trace(ray, objectCount, objects, float(frame) / 10);
            float2 r = float2(hash((tid.x + tid.y * int(imageSize.x)) * uint((randomDirection.x + 0.5) * 10 + uint((bounce + passed) * (imageSize.x + imageSize.y)))),
                              hash((tid.x + tid.y * int(imageSize.x)) * uint((randomDirection.y + 0.5) * 10 + uint((bounce + passed + 8) * (imageSize.x + imageSize.y)))));
            
            
            
            result += ray.energy * PathShade(ray, hit, sky, skySize, objectCount, objects, lightingDirection, skyIntensity, r, hash(tid.x + tid.y * int(imageSize.x) + uint((randomDirection.x + 0.5) * 10 + uint((bounce + passed + 8 + 1) * (imageSize.x + imageSize.y)))));
            if (length(ray.energy) == 0) {
                break;
            }
        }

        image.write(float4(result,1), tid);
        return;
    }
//    float2 r = float2(hash((tid.x + tid.y * uint(imageSize.x)) * (1 + frame + 0 + int(randomDirection.x + 0.5))),
//                      hash((tid.x + tid.y * uint(imageSize.x) + 1) * (1 + frame + 0 + int(randomDirection.y + 0.5))));
//    image.write(float4(r, 0, 1), tid);
}
