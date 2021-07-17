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

float3 steerTowards(float3 heading, float3 target, float strength) {
    return heading + (target - heading) * strength;
}

kernel void boid(uint tid [[thread_position_in_grid]],
                 device Boid * boids [[buffer(0)]],
                 device Object * objects [[buffer(1)]],
                 constant int & boidCount [[buffer(2)]],
                 constant float & perceptionDistance [[buffer(3)]],
                 constant float & perceptionAngle [[buffer(4)]],
                 constant float & deltaT [[buffer(5)]]) {
    // Compute boid headings
    if (int(tid) > boidCount) { return; }
    int counted = 0;
    float3 heading = 0;
    float3 center = 0;
    device Boid & computeBoid = boids[tid];
    for (int i = 0; i < boidCount; i ++) {
        if (int(tid) == i) { continue; }
        Boid boid = boids[i];
        if (distance(boid.position, computeBoid.position) <= perceptionDistance) {
            counted += 1;
            heading += boid.heading;
            center += boid.position;
        }
    }
    heading = heading / float(max(counted, 1));
    center = heading / float(max(counted, 1));
    // FIXME: Add collision detection
    computeBoid.heading = steerTowards(computeBoid.heading, heading, 0.25) * 0.5 + normalize(steerTowards(computeBoid.position, center, 0.5)) * 0.5;
    
    if (length(computeBoid.position) > 50) {
        computeBoid.heading += steerTowards(computeBoid.heading, normalize(-computeBoid.position), distance(computeBoid.position, float3(0) / 50));
    }
    float amnt = 0.01;
    computeBoid.heading += normalize(float3(0) - computeBoid.position) * deltaT * amnt;
    computeBoid.heading /= 1 + deltaT * amnt;
    computeBoid.heading = clamp(computeBoid.heading, float3(-4), float3(4));
    
    computeBoid.position += computeBoid.heading * deltaT;
    
    objects[tid].position = computeBoid.position;
    //FIXME: Add euler's angles
    objects[tid].rotation = float3(0);
}

// Call marchRays for drawing
