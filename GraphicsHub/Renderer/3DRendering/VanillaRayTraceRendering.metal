//
//  VanillaRayTraceRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/16/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../Shared/SharedDataTypes.h"

// MARK: DataTypes
struct Material {
    float3 albedo;
    float3 specular;
    float n;
    float transparency;
};

struct Object {
    int objectType;
    float3 position;
    float3 size;
    float3 rotation;
    Material material;
};

constant int sphere = 0;
constant int box = 1;
constant int triangle = 2;

//  MARK: Ray setup
struct Ray {
    float3 origin;
    float3 direction;
    float3 energy;
    float3 result;
};

Ray CreateRay(float3 origin, float3 direction) {
    Ray ray;
    ray.origin = origin;
    ray.direction = direction;
    ray.energy = float3(1.0f,1.0f,1.0f);
    return ray;
}

Ray CreateCameraRay(float2 uv, float4x4 modelMatrix, float4x4 cameraProjectionMatrix) {
    // Transform the camera origin to world space
    float3 origin = (modelMatrix*float4(0.0f, 0.0f, 0.0f, 1.0f)).xyz;
    
    // Invert the perspective projection of the view-space position
    float3 direction = (cameraProjectionMatrix*float4(uv, 0.0f, 1.0f)).xyz;
    // Transform the direction from camera to world space and normalize
    direction = (modelMatrix*float4(direction, 0.0f)).xyz;
    direction = normalize(direction);
    return CreateRay(origin, direction);
}

struct RayHit {
    float3 position;
    float distance;
    float3 normal;
    Material material;
};

RayHit CreateRayHit() {
    RayHit hit;
    hit.position = float3(0.0f, 0.0f, 0.0f);
    hit.distance = INFINITY;
    hit.normal = float3(0.0f, 0.0f, 0.0f);
    return hit;
}

// MARK: Intersection Functions
uint2 sampleSky (float3 direction, int2 skySize) {
    float xzAngle = (atan2(direction.z, direction.x)/M_PI_F+1.0)/2.0;
    float xzLength = distance(float2(0), direction.xz);
    float yAngle = atan2(direction.y,xzLength)/M_PI_F+0.5;
    return uint2(skySize.x * xzAngle,(1 - yAngle) * skySize.y);
}

void IntersectGroundPlane(Ray ray, thread RayHit &bestHit) {
    // Calculate distance along the ray where the ground plane is intersected
    float t = -ray.origin.y / ray.direction.y;
    if (t > 0 && t < bestHit.distance) {
        Material groundMaterial;
        groundMaterial.albedo = float3(0.7, 0.2, 0.2);
        groundMaterial.specular = float3(0.7, 0.2, 0.2);
        groundMaterial.n = 1;
        groundMaterial.transparency = 0;
        
        bestHit.distance = t;
        bestHit.position = ray.origin + t * ray.direction;
        bestHit.normal = float3(0.0f, 1.0f, 0.0f);
        bestHit.material = groundMaterial;
        
    }
}

void IntersectSphere(Ray ray, thread RayHit &bestHit, Object object) {
    // Calculate distance along the ray where the sphere is intersected
    float3 d = ray.origin - object.position;
    float p1 = -dot(ray.direction, d);
    float p2sqr = p1 * p1 - dot(d, d) + object.size.x * object.size.x;
    if (p2sqr < 0)
        return;
    float p2 = sqrt(p2sqr);
    float t = p1 - p2 > 0 ? p1 - p2 : p1 + p2;
    if (t > 0 && t < bestHit.distance)
    {
        bestHit.distance = t;
        bestHit.position = ray.origin + t * ray.direction;
        bestHit.normal = normalize(bestHit.position - object.position);
        bestHit.material = object.material;
    }
}

void checkFace (Ray ray, thread RayHit &bestHit, Object box, int tSide, int signSide) {
    float3 faceCenter = box.position;
    signSide = signSide * 2 - 1;
    faceCenter += box.size * signSide;
    float t = INFINITY;
    bool inFace = false;
    if (tSide == 0) { //Z
        t = (faceCenter.z - ray.origin.z) / ray.direction.z;
        float3 position = ray.origin + ray.direction * t - box.position;
        if (abs(position.y) <= box.size.y && abs(position.x) <= box.size.x) {
            inFace = true;
        }
    }else if (tSide == 1) {// Y
        t = (faceCenter.y - ray.origin.y)/ray.direction.y;
        float3 position = ray.origin + ray.direction * t - box.position;
        if (abs(position.z) <= box.size.z && abs(position.x) <= box.size.x) {
            inFace = true;
        }
    }else {//X
        t = (faceCenter.x - ray.origin.x)/ray.direction.x;
        float3 position = ray.origin + ray.direction * t - box.position;
        if (abs(position.y) <= box.size.y && abs(position.z) <= box.size.z) {
            inFace = true;
        }
    }
    float Distance = length(ray.direction * t);
    if (inFace && Distance > 0 && Distance < bestHit.distance && t > 0)
    {
        bestHit.distance = Distance;
        bestHit.position = ray.origin + t * ray.direction;
        if (tSide == 0) { //Z
            bestHit.normal = normalize(float3(0,0,signSide));
        }else if (tSide == 1) {// Y
            bestHit.normal = normalize(float3(0,signSide,0));
        }else {//X
            bestHit.normal = normalize(float3(signSide,0,0));
        }
        
        bestHit.material = box.material;
    }
}

void IntersectCube(Ray ray, thread RayHit &bestHit, Object box) {
    for (int i = 0; i < 6; i ++) {
        checkFace(ray, bestHit, box,i / 2, i % 2);
    }
}


// MARK: Tracing
RayHit Trace(Ray ray, int objectCount, constant Object *objects) {
    thread RayHit && bestHit = CreateRayHit();
    IntersectGroundPlane(ray, bestHit);
    for (int i = 0; i < objectCount; i++) {
        if (objects[i].objectType == sphere) {
            IntersectSphere(ray, bestHit, objects[i]);
        } else if (objects[i].objectType == box) {
            IntersectCube(ray, bestHit, objects[i]);
        }
    }
    return bestHit;
}

float3 Shade(thread Ray &ray, RayHit hit, texture2d<float> sky, int2 skyDimensions, int sphereCount, constant Object * objects, float4 lightDirection) {
    
   if (hit.distance < INFINITY) {
       // Return the normal
       ray.origin = hit.position + hit.normal * 0.001f;
       ray.direction = reflect(ray.direction, hit.normal);
       ray.energy *= hit.material.specular;
       
       Ray shadowRay = CreateRay(hit.position + hit.normal * 0.001f, -1 * lightDirection.xyz);
       RayHit shadowHit = Trace(shadowRay, sphereCount, objects);
       if (shadowHit.distance != INFINITY) {
           return float3(0.0f, 0.0f, 0.0f);
       }
       return saturate(dot(hit.normal, lightDirection.xyz) * -1) * lightDirection.w * hit.material.albedo;
   }else {
       // Sample the skybox and write it
       ray.energy = float3(0);
       return sky.read(sampleSky(ray.direction, skyDimensions)).xyz;
   }
}

kernel void processRays (uint2 tid [[thread_position_in_grid]],
                         constant Object * objects [[buffer(0)]],
                         constant int & objectCount [[buffer(1)]],
                         constant float4x4 * cameraMatrices [[buffer(2)]],
                         constant int2 & imageSize [[buffer(3)]],
                         constant int2 & raySize [[buffer(4)]],
                         constant int2 & skySize [[buffer(5)]],
                         constant float4 & lightingDirection [[buffer(6)]],
                         constant float2 & randomDirection [[buffer(7)]],
                         constant int & frame [[buffer(8)]],
                         texture2d<float> sky [[texture(0)]],
                         texture2d<float, access::read_write>image [[texture(1)]]){
    
    float4x4 modelMatrix = cameraMatrices[0];
    float4x4 projectionMatrix = cameraMatrices[1];
    
    tid = shiftedTid(tid, imageSize, raySize, frame);
    if (int(tid.x) < imageSize.x && int(tid.y) < imageSize.y) {
        float2 uv = float2((float2(tid) + randomDirection / 2 + float2(0.5f, 0.5f)) / float2(imageSize.x, imageSize.y) * 2.0f - 1.0f);
        thread Ray &&ray = CreateCameraRay(uv, modelMatrix, projectionMatrix);

        float3 result = float3(0, 0, 0);
        for (int i = 0; i < 8; i++) {
            RayHit hit = Trace(ray, objectCount, objects);
            result += ray.energy * Shade(ray, hit, sky, skySize, objectCount, objects, lightingDirection);
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
