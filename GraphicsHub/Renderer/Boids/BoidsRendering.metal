//
//  BoidsRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/16/21.
//

#include <metal_stdlib>
using namespace metal;
#include "../Shared/SharedDataTypes.h"
#include "../3DRendering/Shared3D.h"

struct Boid {
    float3 heading;
    float3 position;
};

void steerTowards(thread float3 & acceleration, device Boid & boid, float3 target, float strength) {
    acceleration += (target - boid.position) * strength;
}

kernel void boid(uint tid [[thread_position_in_grid]],
                 device Boid * readBoids [[buffer(0)]],
                 device Boid * writeBoids [[buffer(1)]],
                 device Object * objects [[buffer(2)]],
                 constant int & boidCount [[buffer(3)]],
                 constant float & perceptionDistance [[buffer(4)]],
                 constant float & perceptionAngle [[buffer(5)]],
                 constant float & deltaT [[buffer(6)]]) {
    // Compute boid headings
    if (int(tid) > boidCount) { return; }
    device Boid & computeBoid = writeBoids[tid];
    thread float3 && acceleration = float3(0);
//    int counted = 0;
//    float3 heading = 0;
//    float3 center = 0;
//    for (int i = 0; i < boidCount; i ++) {
//        if (int(tid) == i) { continue; }
//        Boid boid = readBoids[i];
//        if (distance(boid.position, computeBoid.position) <= perceptionDistance) {
//            counted += 1;
//            heading += boid.heading;
//            center += boid.position;
//        }
//    }
//    heading = heading / float(max(counted, 1));
//    center = heading / float(max(counted, 1));
//    // FIXME: Add collision detection
//    computeBoid.heading = steerTowards(computeBoid.heading, heading, 0.01) * 0.5 + normalize(steerTowards(computeBoid.position, center, 0.01)) * 0.5 + computeBoid.heading * 0.95;
    
//    if (length(computeBoid.position) > 100) {
//        computeBoid.heading += steerTowards(computeBoid.heading, normalize(-computeBoid.position), 1 - distance(computeBoid.position, float3(0)) / 100);
//            computeBoid.heading += normalize(float3(0) - computeBoid.position) * (1 - distance(computeBoid.position, float3(0)) / 100) * deltaT * 0.5;

//    }
//    float amnt = 0.01;
//    computeBoid.heading += normalize(float3(0) - computeBoid.position) * deltaT * amnt;
//    computeBoid.heading /= 1 + deltaT * amnt;
    
//    steerTowards(acceleration, computeBoid, float3(0), pow(1 - length(computeBoid.position) / 100, 2) * 0.1);
    
//    computeBoid.heading += acceleration * deltaT;
    
    if (length(computeBoid.position) > 100) {
        computeBoid.heading = length(computeBoid.heading) * (normalize(computeBoid.heading) - normalize(computeBoid.position) * 0.5);
        computeBoid.position += normalize(-computeBoid.position) * 0.1;
    }
    
    computeBoid.heading = clamp(computeBoid.heading, float3(-4), float3(4));
//    if (length(computeBoid.heading) < 1) {
//        if (length(computeBoid.heading) == 0) {
//            computeBoid.heading = float3(1, 0,0);
//        }else {
//            computeBoid.heading /= length(computeBoid.heading);
//        }
//    }
    
    computeBoid.position += computeBoid.heading * deltaT;
    
    objects[tid].position = computeBoid.position;
    //FIXME: Add euler's angles
    objects[tid].rotation = float3(0);
}

// Call marchRays for drawing
