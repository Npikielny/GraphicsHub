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
    float3 emission;
};

Material createMaterial(float3 albedo,
                        float3 specular,
                        float n,
                        float transparency,
                        float3 emission);

struct Object {
    int objectType;
    float3 position;
    float3 size;
    float3 rotation;
    Material material;
};

Object createObject(int objectType,
                    float3 position,
                    float3 size,
                    float3 rotation,
                    Material material);

constant int groundPlane = -1;
constant int sphere = 0;
constant int box = 1;
constant int triangle = 2;
constant int Torus = 3;
constant int prism = 4;
constant int cylinder = 5;

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
// MARK: Ray Tracing
void IntersectGroundPlane(Ray ray, thread RayHit &bestHit);
float IntersectSphere(float3 origin, float3 direction, Object object);
void IntersectSphere(Ray ray, thread RayHit &bestHit, Object object);
void IntersectCube(Ray ray, thread RayHit &bestHit, Object box);
float IntersectCube(float3 origin, float3 direction, Object box);

RayHit Trace(Ray ray, int objectCount, constant Object *objects, bool groundPlane);
RayHit Trace(Ray ray, int objectCount, constant Object *objects, float t);
float3 Shade(thread Ray &ray, RayHit hit, texture2d<float> sky, int2 skyDimensions, int sphereCount, constant Object * objects, float4 lightDirection, float skyIntensity);


// MARK: Ray Marching
constant Object GroundPlane = createObject(groundPlane,
                                           float3(0),
                                           float3(0),
                                           float3(0),
                                           createMaterial(float3(0.7, 0.2, 0.2),
                                                          float3(0.7, 0.2, 0.2),
                                                          1,
                                                          1,
                                                          float3(0)));
float GroundPlaneDistance(float3 origin);
float SphereDistance(float3 origin, Object object);
float BoxDistance(float3 ray, Object Box);
float TorusDistance(float3 ray, Object Torus);
float PrismDistance(float3 ray, Object Prism);
float CylinderDistance(float3 ray, Object Cylinder);

float getDistance(float3 origin, Object object);

float SDF(Ray ray, constant Object * objects, int objectCount, thread Object & object, bool groundPlane);

float3 estimateNormal (float3 ray, Object object, float precision);
float3 getNormal(float3 origin, Object object, float precision);

float3 march(int maxIterations, float maxDistance, Ray cameraRay, constant Object * objects, int objectCount, float precision, float4 lightingDirection, texture2d<float, access::read> sky, int2 skySize);
#endif /* Shared3D_h */
