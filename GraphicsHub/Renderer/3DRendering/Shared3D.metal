//
//  Shared3D.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/27/21.
//

#include <metal_stdlib>
using namespace metal;
#include "Shared3D.h"
#include "../Shared/SharedDataTypes.h"
#include "../WhirlNoise/WhirlNoise.h"

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
    ray.energy = 1.0;
    ray.result = 0;
    return ray;
}

float2 uv(uint2 tid, float2 randomDirection, int2 imageSize) {
    return float2((float2(tid) + randomDirection / 2 + float2(0.5f, 0.5f)) / float2(imageSize.x, imageSize.y) * 2.0f - 1.0f);
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
    float xzAngle = (atan2(direction.z, direction.x) / M_PI_F + 1.0) / 2.0;
    float xzLength = distance(0.0, direction.xz);
    float yAngle = atan2(direction.y,xzLength)/M_PI_F + 0.5;
    return uint2(skySize.x * xzAngle,(1 - yAngle) * skySize.y);
}

// MARK: RayTracing
void IntersectGroundPlane(Ray ray, thread RayHit &bestHit) {
    // Calculate distance along the ray where the ground plane is intersected
    float t = -ray.origin.y / ray.direction.y;
    if (t > 0 && t < bestHit.distance) {
        Material groundMaterial;
        groundMaterial.albedo = float3(0.4, 0.2, 0.6) * 0.95;
        groundMaterial.specular = float3(0.4, 0.2, 0.6) * 0.05;
//        groundMaterial.albedo = float3(1) * 0.01;
//        groundMaterial.specular = float3(1) * 0.99;
//        groundMaterial.albedo = float3(0.1) * 0.5;
//        groundMaterial.specular = float3(0.1) * 0.5;
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
    
    
    float3x3 backwardsRotation = rotationMatrix(box.rotation);
    origin = (origin - box.position) * backwardsRotation + box.position;
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
                bestHit.material = triangle.material;
            }
        }
    } else if (RayIntersectsTriangle(ray, triangle.size, triangle.position, triangle.rotation, point, b)) {
        if (point.x != INFINITY) {
            float t = distance(point, ray.origin);
            if (t > 0 && t < bestHit.distance) {
                bestHit.distance = t;
                bestHit.position = ray.origin + t * ray.direction;
                bestHit.normal = normalize(cross(triangle.position - triangle.size, triangle.rotation - triangle.size))*b;
                bestHit.material = triangle.material;
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

void IntersectCone(Ray ray, thread RayHit &bestHit, Object cone) {
    float3x3 matrix = rotationMatrix(cone.rotation);
    
    ray.origin -= cone.position;
    ray.origin *= matrix;
    ray.origin += cone.position;
    ray.direction *= matrix;
    
    float3 co = ray.origin - cone.position;
    
    float a = dot(ray.direction, float3(0, cone.size.z, 0)) * dot(ray.direction, float3(0, cone.size.z, 0)) - cone.size.x * cone.size.x;
    float b = 2. * (dot(ray.direction,float3(0, cone.size.z, 0))*dot(co,float3(0, cone.size.z, 0)) - dot(ray.direction,co) * cone.size.x * cone.size.x);
    float c = dot(co,float3(0, cone.size.z, 0))*dot(co,float3(0, cone.size.z, 0)) - dot(co,co) * cone.size.x * cone.size.x;

    float det = b*b - 4 * a * c;
    if (det < 0.) return;

    det = sqrt(det);
    float t1 = (-b - det) / (2. * a);
    float t2 = (-b + det) / (2. * a);

    // This is a bit messy; there ought to be a more elegant solution.
    float t = t1;
    if ((t < 0 || t2 > 0) && (t2 < t)) t = t2;
    if (t <= 0) return;

    float3 cp = ray.origin + t*ray.direction - cone.position;
    float h = dot(cp, float3(0, 1, 0));
    if (h < 0. || h > 1) return;

    float3 n = normalize(cp * dot(float3(0, cone.size.z, 0), cp) / dot(cp, cp) - float3(0, cone.size.z, 0));

//    return Hit(t, n, s.m);
    if (t > 0 && t < bestHit.distance) {
        bestHit.distance = t;
        bestHit.material = cone.material;
        float3 conePoint = ray.origin + t * ray.direction - cone.position;
        bestHit.normal = n;
        bestHit.material = cone.material;
    }
    
}

float3 getHeight(float3 position, float size, float t) {
    return sin(position.x + position.z + t / 10);
}

void IntersectWaterPlane(Ray ray, thread RayHit &bestHit, float time) {
    // Calculate distance along the ray where the ground plane is intersected
    float t = -ray.origin.y / ray.direction.y;
    float offset = whirlNoise(ray.origin + ray.direction * t + float3(0, time, 0) / 10, float3(3), 2032835902, 0, 1);
//    float3 normal = normalize(float3(abs(cos(offset) / 2),
//                           1,
//                           abs(sin(offset) / 2)));
    float3 originalNormal = whirlNormal(ray.origin + ray.direction * t + float3(0, time, 0) / 10, float3(3), 2032835902);
    float3 normal = originalNormal;
//    if (normal.y < 0) {
//        normal *= -1;
//    }
    normal.y += 15;
//    normal.y *= 2;
    normal = normalize(normal);
    if (originalNormal.y < 0) {
        t += abs(project(ray.direction, normal));
    } else {
        t -= abs(project(ray.direction, normal));
    }
    if (t > 0 && t < bestHit.distance) {
        Material water;
        water.albedo = float3(0.75, 0.75, 0.99) * 0.05;
        water.specular = float3(0.75, 0.75, 0.99) * 0.95;
        water.n = 1;
        water.transparency = 0;

//        bestHit.distance = t;
//        bestHit.position = ray.origin + t * ray.direction;
        
        // x = sin(x + t) * 0.5
        // z = cos(z + t) * 0.5
//        float offset = whirlNoise(bestHit.position + float3(0, time, 0) / 10, float3(3), 2032835902);
//        bestHit.normal = normal;
        
        
        IntersectGroundPlane(ray, bestHit);
        bestHit.normal = normal;
        
//        normalize(float3(
////                                          cos(bestHit.position.x + time * 0.1) * 0.5 * 0.1, // Partial derivates of height with respect to x
//                                          abs(cos(offset) / 2),
//                                          1,
//                                          abs(sin(offset) / 2))
////                                          -sin(bestHit.position.z + time * 0.024) * 0.5 * 0.1
//                                          );
//        if (bestHit.normal.y < 0) {
//            bestHit.normal *= -1;
//        }
//        bestHit.normal.y = abs(bestHit.normal.y);
        bestHit.material = water;
    }
//    if (t > 0 && t < bestHit.distance) {
//        float size = 3;
//        float3 minPosition = floor((ray.origin + ray.direction * t) / size) * size;
//        minPosition.y = 0;
//        Material material = createMaterial(float3(1) * 0.01,
//                                           float3(1) * 0.99,
//                                           1,
//                                           1,
//                                           float3(0));
//        Object triangle;
//        triangle.material = material;
//        for (int x = 0; x <= 1; x ++) {
//            for (int y = 0; y <= 1; y++) {
//                float3 bottomLeft = minPosition + float3(x, 0, y) * size/2;
//                for (int v = 0; v <= 1; v++) {
//                    if (v == 0) {
//                        triangle.position = bottomLeft;
//                        triangle.size = bottomLeft + float3(0, 0, size/2);
//                        triangle.rotation = bottomLeft + float3(size/2, 0, 0);
//                    } else {
//                        triangle.position = bottomLeft + float3(size/2, 0, size/2);
//                        triangle.size = bottomLeft + float3(0, 0, size/2);
//                        triangle.rotation = bottomLeft + float3(size/2, 0, 0);
//                    }
//                    triangle.position.y = getHeight(triangle.position, size, time).y;
//                    triangle.size.y = getHeight(triangle.size, size, time).y;
//                    triangle.rotation.y = getHeight(triangle.rotation, size, time).y;
//                    IntersectTriangle(ray, bestHit, triangle);
//                    float3 temp = triangle.size;
//                    triangle.size = triangle.position;
//                    triangle.position = temp;
//                    IntersectTriangle(ray, bestHit, triangle);
//
//                }
//            }
//        }
//    }
}

void IntersectClouds(Ray ray, thread RayHit &bestHit, float time) {
    // Calculate distance along the ray where the ground plane is intersected
    float minT = (40 - ray.origin.y) / ray.direction.y;
    float maxT = (200 - ray.origin.y) / ray.direction.y;
    float t = INFINITY;
    float threshold = 0.8;
    float offset = recursiveSample(ray.origin, ray.direction, maxT - minT, 5, 0.5, 323852093, 0.5, 0.5, 0.5, 1, 3);
//    for (int i = 0; i < 10; i ++) {
//        t = lerp(minT, maxT, float(i) / 9.0);
//        float3 position = ray.direction * t + ray.origin;
//        float currentOffset = recursiveWhirlNoise(position + float3(time / 3, time / 100, time / 8), float3(500), 0.5, 391017250, -0.5, 0.5, 0.5, 1, 3);
//        offset += currentOffset;
//    }

    float transmittance = exp(-offset);
    
    if (t > 0 && transmittance < threshold && t < bestHit.distance) {
        Material groundMaterial;
//        float factor = clamp(transmittance * 5, 0.0, 1.0);
        groundMaterial.albedo = float3(1);// * factor;
        groundMaterial.specular = float3(0);
        groundMaterial.n = 1;
        groundMaterial.transparency = 0;

        bestHit.distance = t;
        bestHit.position = ray.origin + t * ray.direction;
        bestHit.normal = float3(0.0f, 1.0f, 0.0f);
        bestHit.material = groundMaterial;
    }
}

RayHit Intersect(Ray ray, Object object, thread RayHit & bestHit) {
    if (object.objectType == sphere) {
        IntersectSphere(ray, bestHit, object);
    } else if (object.objectType == box) {
        IntersectCube(ray, bestHit, object);
    } else if (object.objectType == triangle) {
        IntersectTriangle(ray, bestHit, object);
    } else if (object.objectType == cone) {
        IntersectCone(ray, bestHit, object);
    }
    return bestHit;
}

// MARK: Tracing
RayHit Trace(Ray ray, int objectCount, constant Object *objects, bool groundPlane) {
    thread RayHit && bestHit = CreateRayHit();
    if (groundPlane) {
        IntersectGroundPlane(ray, bestHit);
    }
    for (int i = 0; i < objectCount; i++) {
        Intersect(ray, objects[i], bestHit);
    }
    return bestHit;
}

RayHit Trace(Ray ray, int objectCount, constant Object *objects, float t) {
    thread RayHit && bestHit = CreateRayHit();
//    IntersectWaterPlane(ray, bestHit, t);
    IntersectGroundPlane(ray, bestHit);
    IntersectClouds(ray, bestHit, t);
    for (int i = 0; i < objectCount; i++) {
        if (objects[i].objectType == sphere) {
            IntersectSphere(ray, bestHit, objects[i]);
        } else if (objects[i].objectType == box) {
            IntersectCube(ray, bestHit, objects[i]);
        } else if (objects[i].objectType == triangle) {
            IntersectTriangle(ray, bestHit, objects[i]);
        } else if (objects[i].objectType == cone) {
            IntersectCone(ray, bestHit, objects[i]);
        }
    }
    return bestHit;
}

float3 Shade(thread Ray &ray, RayHit hit, texture2d<float> sky, int2 skyDimensions, int objectCount, constant Object * objects, float4 lightDirection, float skyIntensity) {
    
   if (hit.distance < INFINITY) {
       // Return the normal
       ray.origin = hit.position + hit.normal * 0.001f;
       ray.direction = reflect(ray.direction, hit.normal);
       ray.energy *= hit.material.specular;
       
       Ray shadowRay = CreateRay(hit.position + hit.normal * 0.001f, -1 * lightDirection.xyz);
       RayHit shadowHit = Trace(shadowRay, objectCount, objects, true);
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

float3 Shade(thread Ray &ray, RayHit hit, texture2d<float> sky, int2 skyDimensions, float4 lightDirection, float skyIntensity) {
    
   if (hit.distance < INFINITY) {
       // Return the normal
       ray.origin = hit.position + hit.normal * 0.001f;
       ray.direction = reflect(ray.direction, hit.normal);
       ray.energy *= hit.material.specular;
       
       return saturate(dot(hit.normal, lightDirection.xyz) * -1) * lightDirection.w * hit.material.albedo;
   }else {
       // Sample the skybox and write it
       ray.energy = float3(0);
       return sky.read(sampleSky(ray.direction, skyDimensions)).xyz * skyIntensity;
   }
}

// MARK: Ray Marching
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

float ConeDistance(float3 ray, Object cone) {
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
    ray -= cone.position;
    ray *= rotationMatrix(cone.rotation);
    float2 c = cone.size.xy;
    float h = cone.size.z;
    float2 q = h * float2(c.x/c.y,-1.0);
    
    float2 w = float2( length(ray.xz), ray.y );
      float2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
      float2 b = w - q * float2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
      float k = sign( q.y );
      float d = min(dot( a, a ),dot(b, b));
      float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
      return sqrt(d)*sign(s);
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
    } else if (object.objectType == cone) {
        return ConeDistance(origin, object);
    } else {
        return INFINITY;
    }
}

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

float3 march(int maxIterations, float maxDistance, Ray cameraRay, constant Object * objects, int objectCount, float precision, float4 lightingDirection, texture2d<float, access::read> sky, int2 skySize, float skyIntensity) {
    int iterations = 0;
    float dist = 0;
    thread Object && object = Object();
    while (iterations < maxIterations && dist < maxDistance) {
        iterations += 1;
        dist = SDF(cameraRay, objects, objectCount, object, false);
        if (dist < precision) {
            float3 normal = getNormal(cameraRay.origin + cameraRay.direction * (dist - precision), object, precision);
            float3 result = saturate(dot(normal, lightingDirection.xyz) * -1) * lightingDirection.w * object.material.albedo * (1 - object.material.specular) + object.material.specular * sky.read(sampleSky(reflect(cameraRay.direction, normal), skySize)).xyz * skyIntensity;
            return result;
            
        }
        cameraRay.origin += cameraRay.direction * dist;
    }
    return sky.read(sampleSky(cameraRay.direction, skySize)).xyz * skyIntensity;
}
