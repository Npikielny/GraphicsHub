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

//constant int TRIANGLE_MASK_GEOMETRY = 1;
//constant int TRIANGLE_MASK_LIGHT = 2;
//
constant int RAY_MASK_PRIMARY = 3;
//constant int RAY_MASK_SHADOW = 1;
//constant int RAY_MASK_SECONDARY = 1;


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
                            intersection_function_table<instancing> intersectionFunctionTable [[buffer(9)]],
                            texture2d<float, access::read> skyImage [[texture(0)]],
                            texture2d<float, access::write>Image [[texture (1)]]) {
    tid = shiftedTid(tid, imageSize, renderSize, frame);
    if (int(tid.x) > imageSize.x || int(tid.y) > imageSize.y) { return; }
    Ray basicRay = CreateCameraRay(uv(tid, randomDirection, imageSize),
                              modelMatrix,
                              projectionMatrix);
    intersector<instancing> i;
    i.assume_geometry_type(geometry_type::bounding_box);
    i.force_opacity(forced_opacity::opaque);
    i.accept_any_intersection(false);
    typename intersector<instancing>::result_type intersection;
    
    ray ray;
    ray.origin = basicRay.origin;
    ray.direction = basicRay.direction;
    ray.max_distance = INFINITY;
    ray.min_distance = 0;
    
    float3 color = float3(0);
    for (int index = 0; index < 8; index ++) {
        intersection = i.intersect(ray, accelerationStructure, RAY_MASK_PRIMARY, intersectionFunctionTable);
        if (intersection.type != intersection_type::none && intersection.distance < INFINITY) {
            Image.write(float4(objects[intersection.instance_id].material.albedo, 1), tid);
            return;
        } else {
            Image.write(skyImage.read(sampleSky(ray.direction, skySize)), tid);
            return;
        }
    }
//    Image.write(skyImage.read(sampleSky(ray.direction, skySize)), tid);
    Image.write(float4(color, 1), tid);
    // i.intersect(ray, accelerationStructure, RAY_MASK_PRIMARY, intersectionFunctionTable);
}

struct BoundingBoxIntersection {
    bool accept    [[accept_intersection]]; // Whether to accept or reject the intersection.
    float distance [[distance]];            // Distance from the ray origin to the intersection point.
};


[[intersection(bounding_box, instancing)]]
BoundingBoxIntersection boundingBoxIntersection(float3 origin [[origin]],
                                                   float3 direction [[direction]],
                                                   unsigned int primitiveIndex [[primitive_id]],
                                                   device Object * resources [[buffer(0)]]) {
    BoundingBoxIntersection intersection;
    float d;
    if (resources[primitiveIndex].objectType == sphere) {
        d = IntersectSphere(origin, direction, resources[primitiveIndex]);
    } else {
        d = IntersectCube(origin, direction, resources[primitiveIndex]);
    }
//    intersection.distance = d;
//    intersection.accept = true;
    intersection.distance = 1;
    intersection.accept = true;
    return intersection;
}
