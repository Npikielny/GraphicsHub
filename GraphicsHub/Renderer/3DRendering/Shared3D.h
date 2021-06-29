//
//  Shared3D.h
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/27/21.
//

#ifndef Shared3D_h
#define Shared3D_h

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

struct RayHit {
    float3 position;
    float distance;
    float3 normal;
    Material material;
};

float2 uv(uint2 tid, float2 randomDirection, int2 imageSize);

Ray CreateRay(float3 origin, float3 direction);
Ray CreateCameraRay(float2 uv, float4x4 modelMatrix, float4x4 cameraProjectionMatrix);
RayHit CreateRayHit();

uint2 sampleSky (float3 direction, int2 skySize);
void IntersectGroundPlane(Ray ray, thread RayHit &bestHit);
void IntersectSphere(Ray ray, thread RayHit &bestHit, Object object);
void IntersectCube(Ray ray, thread RayHit &bestHit, Object box);

RayHit Trace(Ray ray, int objectCount, constant Object *objects);
float3 Shade(thread Ray &ray, RayHit hit, texture2d<float> sky, int2 skyDimensions, int sphereCount, constant Object * objects, float4 lightDirection);

#endif /* Shared3D_h */
