//
//  SlimeMoldRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/8/21.
//

#include <metal_stdlib>
#include "../Shared/SharedDataTypes.h"
using namespace metal;

struct Node {
    float2 position;
    float angle;
    int species;
};

float randFloat(uint tid, int nodeCount, int frame) {
    return hash(uint(tid + uint(nodeCount * frame)));
}

float2 sampleIntensity(device float * trailMap, Node node, float angle, int2 imageSize, int speciesCount) {
    float2 positionShift = float2(cos(angle + node.angle), sin(angle + node.angle)) * 3;
    if (inImage(int2(node.position) + imageSize / 2, int2(positionShift), imageSize)) {
        int2 position = int2(node.position + positionShift);
        int mapIndex = speciesCount * (position.x + imageSize.x / 2 + (position.y + imageSize.y / 2) * imageSize.x);
        float speciesPrescence = trailMap[mapIndex + node.species];
        float avoidance = 0;
        for (int i = 0; i < speciesCount; i++) {
            if (i == node.species) { continue; }
            avoidance += trailMap[i + mapIndex];
        }
        return float2(speciesPrescence, avoidance);
    }
    return 0;
}

float getPriority(float2 attractiveness, float attraction, float replusion) {
    return attractiveness.x * attraction - attractiveness.y * replusion;
}

kernel void slimeMoldCalculate(uint tid [[thread_position_in_grid]],
                               device Node * nodeBuffer [[buffer(0)]],
                               constant int & nodeCount [[buffer(1)]],
                               constant int2 & imageSize [[buffer(2)]],
                               constant float & speed [[buffer(3)]],
                               constant float & attraction [[buffer(4)]],
                               constant float & repulsion [[buffer(5)]],
                               constant float & turnForce [[buffer(6)]],
                               constant int & frame [[buffer(7)]],
                               constant int & speciesCount [[buffer(8)]],
                               device float * trailMap [[buffer(9)]]) {
    if (tid > uint(nodeCount) - 1) { return; } // Escape if the
    device Node & node = nodeBuffer[tid];
    float angle = 0;
    float maxValue = 0;
    
    float delta = M_PI_F / 4;
    float left = getPriority(sampleIntensity(trailMap, node, -delta, imageSize, speciesCount),
                             attraction,
                             repulsion);
    
    float straight = getPriority(sampleIntensity(trailMap, node, 0, imageSize, speciesCount),
                                 attraction,
                                 repulsion);
    
    float right = getPriority(sampleIntensity(trailMap, node, delta, imageSize, speciesCount),
                              attraction,
                              repulsion);
    
    if (straight >= left && straight >= right) {
        angle = (hash(tid * uint(abs(node.position.x * node.position.y) + frame)) - 0.5) * 0.25;
    } else if (left > right) {
        angle = - delta;
    } else if (right > left) {
        angle = delta;
    } else {
        angle = hash(tid * uint(abs(node.position.x * node.position.y) + frame)) < 0.5 ? left : right;
    }
    
//    for (float i = -1; i <= 1; i ++) {
//        float theta = M_PI_F * i / 3;
//        float2 positionShift = float2(cos(theta + node.angle), sin(theta + node.angle)) * 3;
//        if (inImage(int2(node.position) + imageSize / 2, int2(positionShift), imageSize)) {
//            int2 position = int2(node.position + positionShift);
//            int mapIndex = speciesCount * (position.x + imageSize.x / 2 + (position.y + imageSize.y / 2) * imageSize.x);
//            float speciesPrescence = trailMap[mapIndex + node.species];
//            float avoidance = 0;
//            for (int i = 0; i < speciesCount; i++) {
//                if (i == node.species) { continue; }
//                avoidance += trailMap[i + mapIndex];
//            }
////            float4 imageValue = Image.read(uint2(node.position + positionShift + float2(imageSize) / 2));
////            float value = length(project(colors[node.species], imageValue).xyz);
//            float value = speciesPrescence - avoidance;
//            if (value > maxValue) {
//                maxValue = value;
//                angle = theta;
//            }
//        }
//    }
    
    
    

//    node.angle += angle * sign(maxValue) * (sign(maxValue) == 1 ? attraction : repulsion);
//    if (maxValue < 0) {
//        node.angle -= angle * repulsion;
//    } else {
//        node.angle += angle * attraction;
//    }
    node.angle += angle * turnForce;
    
    node.angle -= float(int(node.angle / M_PI_F / 2)) * M_PI_F * 2;
    float2 potentialPosition = node.position + float2(cos(node.angle), sin(node.angle)) * 3;
    if (!inImage(int2(potentialPosition.x, node.position.y) + imageSize / 2, imageSize)) {
        node.angle = node.angle + M_PI_F;
        node.position += (float2(0) - node.position) * 0.0001;
    }else if (!inImage(int2(node.position.x, potentialPosition.y) + imageSize / 2, imageSize)) {
        node.angle = M_PI_F * 2 - node.angle;
        node.position += (float2(0) - node.position) * 0.0001;
    }

    for (int i = 1; i <= ceil(speed); i ++) {
        float2 newPosition = node.position + float(i) * float2(cos(node.angle), sin(node.angle));
        trailMap[(int(newPosition.x) + imageSize.x / 2 + (int(newPosition.y) + imageSize.y / 2) * imageSize.x) * speciesCount + node.species] = 1;
    }
    node.position += float2(cos(node.angle), sin(node.angle)) * float(speed);
//    int index = int(hash(tid * frame) * float(imageSize.x * imageSize.y * speciesCount));
//    trailMap[index] = 1;
}

kernel void slimeMoldAverage(uint2 tid [[thread_position_in_grid]],
                             constant int2 & imageSize [[buffer(0)]],
                             constant int & diffusionSize [[buffer(1)]],
                             constant float & diffusionRate [[buffer(2)]],
                             constant int & speciesCount  [[buffer(3)]],
                             constant float * colors [[buffer(4)]],
                             constant float * previous [[buffer(5)]],
                             device float * trailMap [[buffer(6)]]) {
    if (int(tid.x) > imageSize.x || int(tid.y) > imageSize.y) { return; }
    
    for (int i = 0; i < speciesCount; i ++) {
        float pixel = 0;
        float counted = 0;
        
        for (int x = -diffusionSize; x <= diffusionSize; x ++) {
            for (int y = -diffusionSize; y <= diffusionSize; y ++) {
                int2 newPosition = int2(tid) + int2(x, y);
                if (inImage(tid, int2(x, y), imageSize)) {
                    counted ++;
                    pixel += previous[int(newPosition.x + newPosition.y * imageSize.x) * speciesCount + i];
                }
            }
        }

        int trailMapIndex = (tid.x + tid.y * imageSize.x) * speciesCount;

        if (counted > 0) {
            trailMap[trailMapIndex + i] = clamp(pixel * (1 - diffusionRate) / counted, 0.0, 1.0);
        } else {
            trailMap[trailMapIndex + i] = clamp(pixel * (1 - diffusionRate), 0.0, 1.0);
        }
    }
}

kernel void drawSlime(uint2 tid [[thread_position_in_grid]],
                      constant int & speciesCount [[buffer(0)]],
                      constant float * trailMap [[buffer(1)]],
                      constant float4 * colors [[buffer(2)]],
                      constant int2 & imageSize [[buffer(3)]],
                      texture2d<float, access::write>image [[texture(0)]]) {
    float4 color = float4(0);
    int trailMapIndex = (int(tid.x) + int(tid.y) * imageSize.x) * speciesCount;
    for (int i = 0; i < speciesCount; i ++) {
        color += colors[i] * trailMap[trailMapIndex + i];
    }
    image.write(clamp(color, float4(0), float4(1)), tid);
}

