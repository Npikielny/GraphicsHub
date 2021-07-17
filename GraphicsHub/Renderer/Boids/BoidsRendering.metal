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
                 device Boid * boids,
                 device Object * objects,
                 constant int & boidCount,
                 constant float & perceptionDistance,
                 constant float & perceptionAngle,
                 constant float & deltaT) {
    // Compute boid headings
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
    computeBoid.position += computeBoid.heading * deltaT;
    
    objects[tid].position = computeBoid.position;
    //FIXME: Add euler's angles
    objects[tid].rotation = float3(0);
}

// Call marchRays for drawing
