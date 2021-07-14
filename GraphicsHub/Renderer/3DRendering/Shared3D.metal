//
//  Shared3D.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/27/21.
//

#include <metal_stdlib>
using namespace metal;
#include "Shared3D.h"

Material createMaterial(float3 albedo,
                        float3 specular,
                        float n,
                        float transparency,
                        float3 emission) {
    Material material = Material();
    material.albedo = albedo;
    material.specular = specular;
    material.n = n;
    material.transparency = transparency;
    material.emission = emission;
    return material;
}

Object createObject(int objectType,
                    float3 position,
                    float3 size,
                    float3 rotation,
                    Material material) {
    Object object = Object();
    object.objectType = objectType;
    object.position = position;
    object.size = size;
    object.rotation = rotation;
    object.material = material;
    return object;
}

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
//        groundMaterial.albedo = float3(0.4, 0.2, 0.6) * 0.95;
//        groundMaterial.specular = float3(0.4, 0.2, 0.6) * 0.05;
//        groundMaterial.albedo = float3(1) * 0.01;
//        groundMaterial.specular = float3(1) * 0.99;
        groundMaterial.albedo = float3(0.1) * 0.5;
        groundMaterial.specular = float3(0.1) * 0.5;
        groundMaterial.n = 1;
        groundMaterial.transparency = 0;
        
        bestHit.distance = t;
        bestHit.position = ray.origin + t * ray.direction;
        bestHit.normal = float3(0.0f, 1.0f, 0.0f);
        bestHit.material = groundMaterial;
    }
}

float IntersectSphere(float3 origin, float3 direction, Object object) {
    float3 d = origin - object.position;
    float p1 = -dot(direction, d);
    float p2sqr = p1 * p1 - dot(d, d) + object.size.x * object.size.x;
    if (p2sqr < 0)
        return INFINITY;
    float p2 = sqrt(p2sqr);
    float t = p1 - p2 > 0 ? p1 - p2 : p1 + p2;
    if (t > 0) {
        return t;
    }
    return INFINITY;
}

void IntersectSphere(Ray ray, thread RayHit &bestHit, Object object) {
    float t = IntersectSphere(ray.origin, ray.direction, object);
    if (t < bestHit.distance)
    {
        bestHit.distance = t;
        bestHit.position = ray.origin + t * ray.direction;
        bestHit.normal = normalize(bestHit.position - object.position);
        bestHit.material = object.material;
    }
}

float3x3 rotationMatrix(float3 rotation) {
    float3x3 Rx = float3x3(float3(1, 0, 0),
                           float3(0, cos(rotation.x), -1 * sin(rotation.x)),
                           float3(0, sin(rotation.x), cos(rotation.x)));
    float3x3 Ry = float3x3(float3(cos(rotation.y), 0, sin(rotation.y)),
                           float3(0, 1, 0),
                           float3(-sin(rotation.y), 0, cos(rotation.y)));
    float3x3 Rz = float3x3(float3(cos(rotation.z), -sin(rotation.z), 0),
                           float3(sin(rotation.z), cos(rotation.z), 0),
                           float3(0, 0, 1));
    return Rx * Ry * Rz;
    
}

float checkFace (float3 origin, float3 direction, Object box, int tSide, int signSide) {
    float3 faceCenter = box.position;
    signSide = signSide * 2 - 1;
    faceCenter += box.size * signSide;
    
    
    float3x3 backwardsRotation = rotationMatrix(-box.rotation);
    origin = (origin - box.position) * backwardsRotation;
    direction = direction * backwardsRotation;
    
    float t = INFINITY;
    bool inFace = false;
    if (tSide == 0) { //Z
        t = (faceCenter.z - origin.z) / direction.z;
        float3 position = origin + direction * t - box.position;
        if (abs(position.y) <= box.size.y && abs(position.x) <= box.size.x) {
            inFace = true;
        }
    }else if (tSide == 1) {// Y
        t = (faceCenter.y - origin.y)/direction.y;
        float3 position = origin + direction * t - box.position;
        if (abs(position.z) <= box.size.z && abs(position.x) <= box.size.x) {
            inFace = true;
        }
    }else {//X
        t = (faceCenter.x - origin.x)/direction.x;
        float3 position = origin + direction * t - box.position;
        if (abs(position.y) <= box.size.y && abs(position.z) <= box.size.z) {
            inFace = true;
        }
    }
    if (inFace && t > 0) {
        return t;
    }
    return INFINITY;
}

void IntersectCube(Ray ray, thread RayHit &bestHit, Object box) {
    for (int i = 0; i < 6; i ++) {
        int tSide = i / 2;
        int signSide = (i % 2) * 2 - 1;
        float t = checkFace(ray.origin, ray.direction, box, i / 2, i % 2);
        
        float3x3 rotation = rotationMatrix(box.rotation);
        
        if (t < bestHit.distance) {
            bestHit.distance = t;
            bestHit.position = ray.origin + t * ray.direction;
            if (tSide == 0) { //Z
                bestHit.normal = normalize(float3(0, 0, signSide)) * rotation;
            }else if (tSide == 1) {// Y
                bestHit.normal = normalize(float3(0, signSide, 0)) * rotation;
            }else {//X
                bestHit.normal = normalize(float3(signSide, 0, 0)) * rotation;
            }
    
            bestHit.material = box.material;
        }
    }
}

float IntersectCube(float3 origin, float3 direction, Object box) {
    float minDistance = INFINITY;
    for (int i = 0; i < 6; i ++) {
        minDistance = min(checkFace(origin, direction, box,i / 2, i % 2), minDistance);
    }
    return minDistance;
}

constant float EPSILON = 1e-8;
//bool IntersectTriangle_MT97(Ray ray, float3 vert0, float3 vert1, float3 vert2,
//    thread float t, thread float u, thread float v)
//{
//    // find vectors for two edges sharing vert0
//    float3 edge1 = vert1 - vert0;
//    float3 edge2 = vert2 - vert0;
//    // begin calculating determinant - also used to calculate U parameter
//    float3 pvec = cross(ray.direction, edge2);
//    // if determinant is near zero, ray lies in plane of triangle
//    float det = dot(edge1, pvec);
//    // use backface culling
//    if (det < EPSILON)
//        return false;
//    float inv_det = 1.0f / det;
//    // calculate distance from vert0 to ray origin
//    float3 tvec = ray.origin - vert0;
//    // calculate U parameter and test bounds
//    u = dot(tvec, pvec) * inv_det;
//    if (u < 0.0 || u > 1.0f)
//        return false;
//    // prepare to test V parameter
//    float3 qvec = cross(tvec, edge1);
//    // calculate V parameter and test bounds
//    v = dot(ray.direction, qvec) * inv_det;
//    if (v < 0.0 || u + v > 1.0f)
//        return false;
//    // calculate t, ray intersects triangle
//    t = dot(edge2, qvec) * inv_det;
//    return true;
//}

//void IntersectTriangle(Ray ray, thread RayHit &bestHit, Object triangle) {
//    thread float t = 1, u = 1, v = 1;
//    if (IntersectTriangle_MT97(ray, triangle.position, triangle.size, triangle.rotation, t, u, v)) {
//        if (t > 0 && t < bestHit.distance)
//        {
//            bestHit.distance = t;
//            bestHit.position = ray.origin + t * ray.direction;
//            bestHit.normal = normalize(cross(triangle.size - triangle.position, triangle.rotation - triangle.position));
//            bestHit.material.albedo = triangle.material.albedo;
//            bestHit.material.specular = triangle.material.specular;
//            bestHit.material.emission = triangle.material.emission;
//        }
//    }
//    else if (IntersectTriangle_MT97(ray, triangle.position, triangle.size, triangle.rotation, t, u, v)) {
//        if (t > 0 && t < bestHit.distance)
//        {
//            bestHit.distance = t;
//            bestHit.position = ray.origin + t * ray.direction;
//            bestHit.normal = normalize(cross(triangle.size - triangle.position, triangle.rotation - triangle.position));
//            bestHit.material.albedo = triangle.material.albedo;
//            bestHit.material.specular = triangle.material.specular;
//            bestHit.material.emission = triangle.material.emission;
//        }
//    }
//}

bool RayIntersectsTriangle(Ray ray,
                           float3 v0, float3 v1, float3 v2,
                           thread float3 & outIntersectionPoint,
                            thread float & b)
{
    const float EPSILON = 0.0000001;
    float3 vertex0 = v0;
    float3 vertex1 = v1;
    float3 vertex2 = v2;
    float3 edge1, edge2, h, s, q;
    float a,f,u,v;
    edge1 = vertex1 - vertex0;
    edge2 = vertex2 - vertex0;
    h = cross(ray.direction, edge2);
    a = dot(edge1, h);
    if (a < EPSILON) {
        b = -1;
    }else {
        b = 1;
    }
    if (a > -EPSILON && a < EPSILON)
        return false;    // This ray is parallel to this triangle.
    f = 1.0/a;
    s = ray.origin - vertex0;
    u = f * dot(s, h);
    if (u < 0.0 || u > 1.0)
        return false;
    q = cross(s, edge1);
    v = f * dot(ray.direction, q);
    if (v < 0.0 || u + v > 1.0)
        return false;
    // At this stage we can compute t to find out where the intersection point is on the line.
    float t = f * dot(edge2, q);
    if (t > EPSILON) // ray intersection
    {
        outIntersectionPoint = ray.origin + ray.direction * t;
        return true;
    }
    else // This means that there is a line intersection but not a ray intersection.
        return false;
}

void IntersectTriangle(Ray ray, thread RayHit & bestHit, Object triangle) {
//    thread float t, u, v, b;
//    if (IntersectTriangle_MT97(ray, triangle.v0, triangle.v1, triangle.v2, t, u, v, b)) {
//        if (t > 0 && t < bestHit.distance) {
//            bestHit.distance = t;
//            bestHit.position = ray.origin + t * ray.direction;
//            bestHit.normal = normalize(cross(triangle.v1 - triangle.v0, triangle.v2 - triangle.v0)) * b;
//            bestHit.albedo = triangle.albedo;
//            bestHit.specular = triangle.specular;
//        }
//    }
    thread float3 point = float3(INFINITY);
    thread float b = 0;
    if (RayIntersectsTriangle(ray, triangle.position, triangle.size, triangle.rotation, point, b)) {
        if (point.x != INFINITY) {
            float t = distance(point, ray.origin);
            if (t > 0 && t < bestHit.distance) {
                bestHit.distance = t;
                bestHit.position = ray.origin + t * ray.direction;
                bestHit.normal = normalize(cross(triangle.size - triangle.position, triangle.rotation - triangle.position))*b;
                bestHit.material.albedo = triangle.material.albedo;
                bestHit.material.specular = triangle.material.specular;
            }
        }
    } else if (RayIntersectsTriangle(ray, triangle.size, triangle.position, triangle.rotation, point, b)) {
        if (point.x != INFINITY) {
            float t = distance(point, ray.origin);
            if (t > 0 && t < bestHit.distance) {
                bestHit.distance = t;
                bestHit.position = ray.origin + t * ray.direction;
                bestHit.normal = normalize(cross(triangle.position - triangle.size, triangle.rotation - triangle.size))*b;
                bestHit.material.albedo = triangle.material.albedo;
                bestHit.material.specular = triangle.material.specular;
            }
        }
    }
//    if (testerRayTriangleIntersect(ray.origin, ray.direction, triangle.v0, triangle.v1, triangle.v2, t, u, v, b)) {
//        if (t > 0 && t < bestHit.distance) {
//            bestHit.distance = t;
//            bestHit.position = ray.origin + t * ray.direction;
////            bestHit.normal = normalize(cross(triangle.v1 - triangle.v0, triangle.v2 - triangle.v0)) * b;
//            bestHit.normal = normalize(float3(u,v,b));
//            bestHit.albedo = triangle.albedo;
//            bestHit.specular = triangle.specular;
//        }
//    }
}

float3 getHeight(float3 position, float size, float t) {
    return sin(position.x + position.z + t / 10);
}

void IntersectWaterPlane(Ray ray, thread RayHit &bestHit, float time) {
    // Calculate distance along the ray where the ground plane is intersected
    float t = -ray.origin.y / ray.direction.y;
    if (t > 0 && t < bestHit.distance) {
        float size = 3;
        float3 minPosition = floor((ray.origin + ray.direction * t) / size) * size;
        minPosition.y = 0;
        Material material = createMaterial(float3(1) * 0.01,
                                           float3(1) * 0.99,
                                           1,
                                           1,
                                           float3(0));
        Object triangle;
        triangle.material = material;
        for (int x = 0; x <= 1; x ++) {
            for (int y = 0; y <= 1; y++) {
                float3 bottomLeft = minPosition + float3(x, 0, y) * size/2;
                for (int v = 0; v <= 1; v++) {
                    if (v == 0) {
                        triangle.position = bottomLeft;
                        triangle.size = bottomLeft + float3(0, 0, size/2);
                        triangle.rotation = bottomLeft + float3(size/2, 0, 0);
                    } else {
                        triangle.position = bottomLeft + float3(size/2, 0, size/2);
                        triangle.size = bottomLeft + float3(0, 0, size/2);
                        triangle.rotation = bottomLeft + float3(size/2, 0, 0);
                    }
                    triangle.position.y = getHeight(triangle.position, size, time).y;
                    triangle.size.y = getHeight(triangle.size, size, time).y;
                    triangle.rotation.y = getHeight(triangle.rotation, size, time).y;
                    IntersectTriangle(ray, bestHit, triangle);
                    float3 temp = triangle.size;
                    triangle.size = triangle.position;
                    triangle.position = temp;
                    IntersectTriangle(ray, bestHit, triangle);
                    
                }
            }
        }
    }
}

// MARK: Tracing
RayHit Trace(Ray ray, int objectCount, constant Object *objects, bool groundPlane) {
    thread RayHit && bestHit = CreateRayHit();
    if (groundPlane) {
        IntersectGroundPlane(ray, bestHit);
    }
    for (int i = 0; i < objectCount; i++) {
        if (objects[i].objectType == sphere) {
            IntersectSphere(ray, bestHit, objects[i]);
        } else if (objects[i].objectType == box) {
            IntersectCube(ray, bestHit, objects[i]);
        } else if (objects[i].objectType == triangle) {
            IntersectTriangle(ray, bestHit, objects[i]);
        }
    }
    return bestHit;
}

RayHit Trace(Ray ray, int objectCount, constant Object *objects, float t) {
    thread RayHit && bestHit = CreateRayHit();
    IntersectWaterPlane(ray, bestHit, t);
    for (int i = 0; i < objectCount; i++) {
        if (objects[i].objectType == sphere) {
            IntersectSphere(ray, bestHit, objects[i]);
        } else if (objects[i].objectType == box) {
            IntersectCube(ray, bestHit, objects[i]);
        } else if (objects[i].objectType == triangle) {
            IntersectTriangle(ray, bestHit, objects[i]);
        }
    }
    return bestHit;
}

float3 Shade(thread Ray &ray, RayHit hit, texture2d<float> sky, int2 skyDimensions, int sphereCount, constant Object * objects, float4 lightDirection, float skyIntensity) {
    
   if (hit.distance < INFINITY) {
       // Return the normal
       ray.origin = hit.position + hit.normal * 0.001f;
       ray.direction = reflect(ray.direction, hit.normal);
       ray.energy *= hit.material.specular;
       
       Ray shadowRay = CreateRay(hit.position + hit.normal * 0.001f, -1 * lightDirection.xyz);
       RayHit shadowHit = Trace(shadowRay, sphereCount, objects, true);
       if (shadowHit.distance != INFINITY) {
           return float3(0.0f, 0.0f, 0.0f);
       }
       return saturate(dot(hit.normal, lightDirection.xyz) * -1) * lightDirection.w * hit.material.albedo;
   }else {
       // Sample the skybox and write it
       ray.energy = float3(0);
       return sky.read(sampleSky(ray.direction, skyDimensions)).xyz * skyIntensity;
   }
}

float2 uv(uint2 tid, float2 randomDirection, int2 imageSize) {
    return float2((float2(tid) + randomDirection / 2 + float2(0.5f, 0.5f)) / float2(imageSize.x, imageSize.y) * 2.0f - 1.0f);
}
