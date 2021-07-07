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

[[kernel]]
void slimeMoldCalculate(uint tid [[thread_position_in_grid]],
                        device Node * nodeBuffer [[buffer(0)]],
                        constant int & nodeCount [[buffer(1)]],
                        constant int2 & imageSize [[buffer(2)]],
                        constant float & attraction [[buffer(3)]],
                        constant float4 * colors [[buffer(4)]],
                        constant float & speed [[buffer(5)]],
                        constant float & turnForce [[buffer(6)]],
                        constant float & forwardForce [[buffer(7)]],
                        constant float & detectorStrength [[buffer(8)]],
                        constant int & frame [[buffer(9)]],
                        texture2d<float, access::read_write> Image) {
    if (tid > uint(nodeCount) - 1) { return; }
    device Node & node = nodeBuffer[tid];
    float angle = 0;
    float maxValue = 0;
    for (float i = -1; i <= 1; i ++) {
        float theta = M_PI_F * i / 3;
        float2 positionShift = float2(cos(theta + node.angle), sin(theta + node.angle)) * 3;
        if (inImage(int2(node.position) + imageSize / 2, int2(positionShift), imageSize)) {
            float4 imageValue = Image.read(uint2(node.position + positionShift + float2(imageSize) / 2));
            float value = length(project(colors[node.species], imageValue).xyz);
            if (value > maxValue) {
                maxValue = value;
                angle = theta;
            }
        }
    }
    
//    node.angle += angle * attraction;
//    node.angle += (randFloat(tid, nodeCount, frame) * sign(angle) * 0.25 + M_PI_F / 3 * sign(angle)) * turnForce;
    node.angle += angle * attraction;
    node.angle -= float(int(node.angle / M_PI_F / 2)) * M_PI_F * 2;
    float2 potentialPosition = node.position + float2(cos(node.angle), sin(node.angle)) * 3;
    if (!inImage(int2(potentialPosition.x, node.position.y) + imageSize / 2, imageSize)) {
        node.angle = node.angle + M_PI_F;
    }else if (!inImage(int2(node.position.x, potentialPosition.y) + imageSize / 2, imageSize)) {
        node.angle = M_PI_F * 2 - node.angle;
    }
    
    for (int i = 1; i <= ceil(speed); i ++) {
        Image.write(colors[node.species], uint2(node.position + float2(cos(node.angle), sin(node.angle)) * float(i) + float2(imageSize) / 2));
    }
    node.position += float2(cos(node.angle), sin(node.angle)) * float(speed);

//    device Node & node = nodeBuffer[tid];
//
//    float angle = 0;
//    float maxValue = length(float4(1)) * (1 - detectorStrength);
////    for (float i = -1; i <= 1; i ++) {
////        float theta = M_PI_F  * i / 3;
////        float2 positionShift = float2(cos(theta + node.angle), sin(theta + node.angle)) * 10 * speed;
////        if (inImage(int2(node.position) + imageSize / 2, int2(positionShift), imageSize)) {
////            float4 imageValue = Image.read(uint2(node.position + positionShift + float2(imageSize) / 2));
////            float value = length(project(colors[node.species], imageValue).xyz);
////            if (value > maxValue) {
////                maxValue = value;
////                angle = theta;
////            }
////        }
////    }
//    for (float i = -2; i <= 2; i ++) {
//        if (i == 0) { continue; }
//        float theta = M_PI_F * 2 * i / 10;
//        float2 positionShift = float2(cos(theta + node.angle), sin(theta + node.angle)) * 3;
//        if (inImage(int2(positionShift + node.position) + imageSize / 2, imageSize)) {
//            float4 imageValue = Image.read(uint2(int2(positionShift + node.position) + imageSize / 2));
//            float value = length(imageValue);
//            angle += theta * value;
//            Image.write(colors[1] * 0.5, uint2(int2(positionShift + node.position) + imageSize / 2));
//        }
//    }
//    node.angle += angle / 4 * attraction;
//////    node.angle = (angle * turnForce + node.angle * forwardForce) / ( (turnForce + forwardForce == 0) ? 1 : (turnForce + forwardForce) );
////    if (turnForce + forwardForce > 0) {
////        node.angle = (angle * attraction * turnForce + node.angle * forwardForce) / (turnForce + forwardForce);
////    }
////    node.angle += hash(tid + uint((imageSize.x * imageSize.y) * frame)) - 0.5;
//    node.angle -= float(int(node.angle / M_PI_F / 2)) * M_PI_F * 2;
////    float2 potentialPosition = node.position + float2(cos(node.angle), sin(node.angle)) * 3;
////
////    if (abs(node.position.x) >= imageSize.x) {
////        node.angle = M_PI_F - node.angle;
////        node.position += float2(cos(node.angle), sin(node.angle));
//////        if (node.position.x > float(imageSize.x / 2)) {
//////            node.angle = clamp(node.angle, M_PI_F / 2, M_PI_F * 3 / 2)
//////        } else if (node.position.x < 0 ) {
//////            node.angle = clamp(node.angle, M_PI_F / 2, M_PI_F * 3 / 2)
//////        }
////    }
////    if (abs(node.position.y) >= imageSize.x) {
////        node.angle = M_PI_F - node.angle;
////    }
//
//    if (abs(node.position.x) > float(imageSize.x) / 2) {
//        node.position.x = clamp(node.position.x, - float(imageSize.x) / 2, float(imageSize.x) / 2);
//        node.angle = M_PI_F - node.angle;
//    }
//
//    if (abs(node.position.y) > float(imageSize.y) / 2) {
//        node.position.y = clamp(node.position.y, - float(imageSize.y) / 2, float(imageSize.y) / 2);
//        node.angle = - node.angle;
//    }
//
//    for (int i = 0; i <= speed; i ++) {
//        Image.write(colors[node.species], uint2(node.position + float2(cos(node.angle), sin(node.angle)) * float(i) + float2(imageSize) / 2));
//    }
//    node.position += float2(cos(node.angle), sin(node.angle)) * float(speed);
////
////    for (int i = 1; i <= speed; i ++) {
////        Image.write(colors[node.species], uint2(node.position + float2(cos(node.angle), sin(node.angle)) * float(i) + float2(imageSize) / 2));
////    }
////    node.position += float2(cos(node.angle), sin(node.angle)) * float(speed);
////    Image.write(colors[node.species], uint2(node.position + float2(imageSize) / 2));
}


[[kernel]]
void slimeMoldAverage(uint2 tid [[thread_position_in_grid]],
                      constant int2 & imageSize [[buffer(0)]],
                      constant int & diffusionSize [[buffer(1)]],
                      constant float & diffusionRate [[buffer(2)]],
                      texture2d<float, access::read_write> lastImage [[texture(0)]],
                      texture2d<float, access::read_write> image [[texture(1)]]) {
    if (int(tid.x) > imageSize.x || int(tid.y) > imageSize.y) {
        return;
    }
    
    float4 pixel = float4(0);
    float counted = 0;
    for (int x = -diffusionSize; x <= diffusionSize; x ++) {
        for (int y = -diffusionSize; y <= diffusionSize; y ++) {
            int2 newPosition = int2(tid) + int2(x, y);
            if (inImage(tid, int2(x, y), imageSize)) {
                counted ++;
                pixel += lastImage.read(uint2(newPosition));
            }
        }
    }
    if (counted > 0) {
        image.write(float4(pixel.xyz * (1 - diffusionRate) / counted, 1), tid);
    } else {
        image.write(float4(pixel.xyz * (1 - diffusionRate), 1), tid);
    }
}

