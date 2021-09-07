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

constant int FACE_MASK_NONE =       0;
constant int FACE_MASK_NEGATIVE_X = (1 << 0);
constant int FACE_MASK_POSITIVE_X = (1 << 1);
constant int FACE_MASK_NEGATIVE_Y = (1 << 2);
constant int FACE_MASK_POSITIVE_Y = (1 << 3);
constant int FACE_MASK_NEGATIVE_Z = (1 << 4);
constant int FACE_MASK_POSITIVE_Z = (1 << 5);
constant int FACE_MASK_ALL =        ((1 << 6) - 1);

constant int GEOMETRY_MASK_TRIANGLE = 1;
constant int GEOMETRY_MASK_SPHERE =   2;
constant int GEOMETRY_MASK_LIGHT =    4;

constant int GEOMETRY_MASK_GEOMETRY = (GEOMETRY_MASK_TRIANGLE | GEOMETRY_MASK_SPHERE);

constant int RAY_MASK_PRIMARY =   (GEOMETRY_MASK_GEOMETRY | GEOMETRY_MASK_LIGHT);
constant int RAY_MASK_SHADOW =    GEOMETRY_MASK_GEOMETRY;
constant int RAY_MASK_SECONDARY = GEOMETRY_MASK_GEOMETRY;

kernel void acceleratedRays(uint2 tid [[thread_position_in_grid]],
                            constant int2 & imageSize [[buffer(0)]],
                            constant int2 & renderSize [[buffer(1)]],
                            constant int2 & skySize [[buffer(2)]],
                            constant float2 & randomDirection [[buffer(3)]],
                            constant float4x4 & modelMatrix [[buffer(4)]],
                            constant float4x4 & projectionMatrix [[buffer(5)]],
                            constant int & frame [[buffer(6)]],
                            constant Object * objects [[buffer(7)]],
                            instance_acceleration_structure accelerationStructure [[buffer(8)]],
                            intersection_function_table<triangle_data, instancing> intersectionFunctionTable [[buffer(9)]],
                            texture2d<float> skyImage [[texture(0)]],
                            texture2d<float, access::write>Image [[texture (1)]]) {
    tid = shiftedTid(tid, imageSize, renderSize, frame);
    if (int(tid.x) > imageSize.x || int(tid.y) > imageSize.y) { return; }
    Ray basicRay = CreateCameraRay(uv(tid, randomDirection, imageSize),
                              modelMatrix,
                              projectionMatrix);
    ray ray;
    ray.origin = basicRay.origin;
    ray.direction = basicRay.direction;
    ray.max_distance = INFINITY;
    
    intersector<triangle_data, instancing> acceleratedIntersector;
    typename intersector<triangle_data, instancing>::result_type intersection;
    
    for (int bounce = 0; bounce < 3; bounce ++) {
        acceleratedIntersector.accept_any_intersection(false);
        intersection = acceleratedIntersector.intersect(ray, accelerationStructure, intersectionFunctionTable);
        if (intersection.type == intersection_type::none) {
            basicRay.result += basicRay.energy * skyImage.read(sampleSky(ray.direction, skySize)).xyz;
            Image.write(float4(basicRay.result, 1), tid);
            return;
        } else {
            basicRay.direction = ray.direction;
            basicRay.origin = ray.origin;
            RayHit bestHit = CreateRayHit();
            Intersect(basicRay, objects[intersection.primitive_id], bestHit);
            basicRay.result += basicRay.energy * Shade(basicRay, bestHit, skyImage, skySize, float4(0.1, -0.4, 0.1, 1), 1);
            
            ray.origin = basicRay.origin;
            ray.direction = basicRay.origin;
        }
    }
    
    Image.write(float4(basicRay.result, 1), tid);
//    intersector<instancing> i;
//    i.assume_geometry_type(geometry_type::bounding_box);
//    i.force_opacity(forced_opacity::opaque);
//    i.accept_any_intersection(false);
//    typename intersector<instancing>::result_type intersection;
//
//    ray ray;
//    ray.origin = basicRay.origin;
//    ray.direction = basicRay.direction;
//    ray.max_distance = INFINITY;
//
//
//    float3 color = float3(0);
////    for (int index = 0; index < 8; index ++) {
//    intersection = i.intersect(ray, accelerationStructure, RAY_MASK_SECONDARY, intersectionFunctionTable);
//    if (intersection.type != intersection_type::none && intersection.distance < INFINITY) {
//        Image.write(float4(objects[intersection.instance_id].material.albedo, 1), tid);
//        return;
//    } else {
//        Image.write(skyImage.read(sampleSky(ray.direction, skySize)), tid);
//        return;
//    }
////    }
////    Image.write(skyImage.read(sampleSky(ray.direction, skySize)), tid);
//    Image.write(float4(color, 1), tid);
//    // i.intersect(ray, accelerationStructure, RAY_MASK_PRIMARY, intersectionFunctionTable);
}

struct BoundingBoxIntersection {
    bool accept    [[accept_intersection]]; // Whether to accept or reject the intersection.
    float distance [[distance]];            // Distance from the ray origin to the intersection point.
};

[[intersection(bounding_box, triangle_data, instancing)]]
BoundingBoxIntersection sphereIntersectionFunction(// Ray parameters passed to the ray intersector below
                                        float3 origin               [[origin]],
                                        float3 direction            [[direction]],
                                        float minDistance           [[min_distance]],
                                        float maxDistance           [[max_distance]],
                                        // Information about the primitive.
                                        unsigned int primitiveIndex [[primitive_id]],
                                        unsigned int geometryIndex  [[geometry_intersection_function_table_offset]],
                                        // Custom resources bound to the intersection function table.
                                        device Object *objects      [[buffer(0)]]) {
    device Object & sphere = objects[primitiveIndex];

    // Check for intersection between the ray and sphere mathematically.
    float3 oc = origin - sphere.position;

//    float a = dot(direction, direction);
//    float b = 2 * dot(oc, direction);
//    float c = dot(oc, oc) - sphere.radius * sphere.radius;

//    float disc = b * b - 4 * a * c;

    BoundingBoxIntersection ret;
    ret.accept = false;
    float p1 = -dot(direction, oc);
    float p2sqr = p1 * p1 - dot(oc, oc) + sphere.size.x * sphere.size.x;
    if (p2sqr < 0)
        return ret;
    
    float p2 = sqrt(p2sqr);
    float t = p1 - p2 > 0 ? p1 - p2 : p1 + p2;
    if (t > 0) {
        ret.accept = true;
        ret.distance = t;
        return ret;
        
    }
    return ret;
    
}

//
//[[intersection(bounding_box, instancing)]]
//BoundingBoxIntersection boundingBoxIntersection(float3 origin [[origin]],
//                                                   float3 direction [[direction]],
//                                                   unsigned int primitiveIndex [[primitive_id]],
//                                                   device Object * resources [[buffer(0)]]) {
//    BoundingBoxIntersection intersection;
//    float d;
//    if (resources[primitiveIndex].objectType == sphere) {
//        d = IntersectSphere(origin, direction, resources[primitiveIndex]);
//    } else {
//        d = IntersectCube(origin, direction, resources[primitiveIndex]);
//    }
////    intersection.distance = d;
////    intersection.accept = true;
//    intersection.distance = 1;
//    intersection.accept = true;
//    return intersection;
//}
