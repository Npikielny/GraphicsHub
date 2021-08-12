//
//  Perlin.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/25/21.
//

#include <metal_stdlib>
using namespace metal;
#include "Perlin.h"
#include "../Shared/SharedDataTypes.h"

//int overflowMultiplication (int x1, int x2) {
//    int multiplication = x1 * x2;
//    int overHang = int(pow(float(2), float(32)));
//    int overflow = (multiplication + overHang / 2) / overHang;
//    return multiplication - overflow * overHang;
//}
float findNoise(half x, half z, int noiseX, int noiseZ, int noiseSeed, int seed) {
//    int n = noiseX * int(x) + noiseZ * int(z) + noiseSeed * seed;
//    n = (n >> 13) ^ n;
//    n = overflowMultiplication(n, overflowMultiplication(n, overflowMultiplication(n, (60493 + 19990303))) + 1376312589) & 0x7fffffff;
//    return 1 - float (n) / 1073741824;
    return hash(int(hash(x) * hash(z) * 1376312589) + noiseSeed);
}

//float createNoise(int x, int y, int noiseX, int noiseZ, int noiseSeed, int seed) {
//    return int(abs(findNoise(half(x), half(y), noiseX, noiseZ, noiseSeed, seed)) * 255) % 255;
//}

float3 interpolatedValue(float3 MIN, float3 MAX, float value) {
    return value * MAX + (1 - value) * MIN;
}

float3 findPoint(int2 point, int noiseX, int noiseZ, int noiseSeed, int seed) {
    return float3(float(point.x), findNoise(point.x, point.y, noiseX, noiseZ, noiseSeed, seed), float(point.y));
}

//float3x3 createMatrix (int2 point1, int2 point2, int2 point3, int noiseX, int noiseZ, int noiseSeed, int seed, int widthValue, int heightValue) {
//    float3x3 planeMatrix = float3x3(
//                                    findPoint(point3 - point1, noiseX, noiseZ, noiseSeed, seed),
//                                    findPoint(point2 - point1, noiseX, noiseZ, noiseSeed, seed),
//                                    float3(0)
//                                    );
//    return planeMatrix;
//}
float3x3 createMatrix (int2 point1, int2 point2, int2 point3, int noiseX, int noiseZ, int noiseSeed, int seed, int widthValue, int heightValue) {
//    float3x3 returnMatrix = float3x3(0);
//    returnMatrix[0][0] = point1.x;
//    returnMatrix[1][0] = point2.x;
//    returnMatrix[2][0] = point3.x;
//    returnMatrix[0][2] = point1.y;
//    returnMatrix[1][2] = point2.y;
//    returnMatrix[2][2] = point3.y;
//
    float3x3 returnMatrix = float3x3(0);
    for (int i = 0; i < 3; i++) {
        int2 point = int2(0,0);
        if (i == 0) {
            point = point1;
        }else if (i == 1) {
            point = point2;
        }else {
            point = point3;
        }
        for (int k = 0; k < 3; k++) {
            if (k == 0) {
                returnMatrix[i][k] = point.x;
            }else if (k == 1) {
                int x = point.x;
                if (x > widthValue) {
                    x = 0;
                }
                int y = point.x;
                
                if (y > heightValue) {
                    y = 0;
                }
                returnMatrix[i][k] = findNoise(point.x, point.y, noiseX, noiseZ, noiseSeed, seed);
//                returnMatrix[i][k] = createNoise(x, y);
            }else {
                returnMatrix[i][k] = point.y;
            }
        }
    }
    return returnMatrix;
}

float perlin (int2 position,
                     int sideLength, // Max Chunk Size
                     int octaves,
                     int noiseX,
                     int noiseZ,
                     int noiseSeed,
                     float zoom) {
    int x = position.x;
    int y = position.y;
    float netValue = 0;
    
    int power = int(pow(2.0, float(1))); // Smaller -> Wider and larger, gradual changes... Larger -> Thinner and smaller, sharp changes
    int chunkSize = sideLength / power;
    int2 minChunk = int2(x / chunkSize, y / chunkSize) * (chunkSize); // Min coordinate of the chunk
    int2 maxChunk = minChunk + chunkSize; // Max coordinate of the chunk
    float point1 = findPoint(minChunk, noiseX, noiseZ, noiseSeed, 1).y;
    float point2 = findPoint(int2(maxChunk.x, minChunk.y), noiseX, noiseZ, noiseSeed, 1).y;
    float point3 = findPoint(int2(minChunk.x, maxChunk.y), noiseX, noiseZ, noiseSeed, 1).y;
    float point4 = findPoint(int2(maxChunk.x, maxChunk.y), noiseX, noiseZ, noiseSeed, 1).y;
    
    // If point is in bottom right -> { assign bottom right triangle to verts } otherwise { assign top left triangle to verts }
    float xPct = float(x - minChunk.x) / float(chunkSize);
        float value = lerp(
                           lerp(point1, point2, xPct),
                           lerp(point3, point4, xPct),
                           float(y - minChunk.y) / float(chunkSize));
//    float value = lerp(point1, point2, xPct);
//    netValue += value * 1 / float(power);
    netValue = value;
    
    
    
    
    // FIXME: Everything XD
//    for (int octave = 0; octave <= octaves; octave ++) {
//        int power = int(pow(2.0, float(octave))); // Smaller -> Wider and larger, gradual changes... Larger -> Thinner and smaller, sharp changes
//        int chunkSize = sideLength / power;
//        int2 minChunk = int2(x / chunkSize, y / chunkSize) * (chunkSize); // Min coordinate of the chunk
//        int2 maxChunk = minChunk + chunkSize + int2(1, 0); // Max coordinate of the chunk
//        minChunk.y = 0;
//        maxChunk.y = 0;
//        float point1 = findPoint(minChunk, noiseX, noiseZ, noiseSeed, 1).y;
//        float point2 = findPoint(int2(maxChunk.x, minChunk.y), noiseX, noiseZ, noiseSeed, 1).y;
//        float point3 = findPoint(int2(minChunk.x, maxChunk.y), noiseX, noiseZ, noiseSeed, 1).y;
//        float point4 = findPoint(int2(maxChunk.x, maxChunk.y), noiseX, noiseZ, noiseSeed, 1).y;
//
//        // If point is in bottom right -> { assign bottom right triangle to verts } otherwise { assign top left triangle to verts }
//        float xPct = float(x - minChunk.x) / float(chunkSize);
////        float value = lerp(
////                           lerp(point1, point2, xPct),
////                           lerp(point3, point4, xPct),
////                           float(y - minChunk.y) / float(chunkSize));
//        float value = lerp(point1, point2, xPct);
//        netValue += value * 1 / float(power);
//
//    }
    
//    return clamp(netValue / (2 * (1 - pow(0.5, float(octaves) + 1.0))), 0.0, 1.0); // Scale values from 0 to 1
//    return netValue / (2 * (1 - pow(0.5, float(octaves) + 1.0))); // Scale values from 0 to 1
    return netValue;
}


float perlin2 (int2 position,
                     int sideLength, // Max Chunk Size
                     int octaves,
                     int noiseX,
                     int noiseZ,
                     int noiseSeed,
                     float zoom,
               float4 v) {
    int x = position.x;
    int y = position.y;
    float netValue = 0;
    for (int octave = 0; octave <= octaves; octave ++) {
        int power = int(pow(2.0, float(octave))); // Smaller -> Wider and larger, gradual changes... Larger -> Thinner and smaller, sharp changes
        int chunkSize = sideLength / power;
        int2 minChunk = int2(x / chunkSize, y / chunkSize) * (chunkSize); // Min coordinate of the chunk
        int2 maxChunk = minChunk + chunkSize; // Max coordinate of the chunk
        
        float3 point1; // Vertex of Triangle
        float3 point2 = float3(minChunk.x, v.x, minChunk.y);
        float3 point3;
        
        // If point is in bottom right -> { assign bottom right triangle to verts } otherwise { assign top left triangle to verts }
        if (y - minChunk.y < ((maxChunk.y - minChunk.y) / (maxChunk.x - minChunk.x) * (x - minChunk.x))) {
            // below midpoint
            point1 = float3(maxChunk.x, v.y, minChunk.y);
            point3 = float3(maxChunk.x, v.z, maxChunk.y);
        }else {
            // above || on midpoint
            point1 = float3(maxChunk.x, v.z, maxChunk.y);
            point3 = float3(minChunk.x, v.w, maxChunk.y);
        }
        float3 vector1 = point1 - point2;
        float3 vector2 = point3 - point2;
        float3 coefficients = cross(vector1, vector2);
        float D = float(coefficients.x * point2.x + coefficients.y * point2.y + coefficients.z * point2.z);
        float4 planarCoefficients = float4(coefficients.x, coefficients.y, coefficients.z, D);
        float value = (D - (planarCoefficients.x * float(x - point2.x) + planarCoefficients.z * float(y - point2.z)))/planarCoefficients.y + point2.y;
//        float2 pos = (float2(x,y) - point2.xz) / float2(vector1.x, vector2.z);
//        float value = (vector1 * pos.x / 2 + vector2 * pos.y / 2 + point2).y;
        netValue += value * 1 / float(power);
    }
    return netValue / (2 * (1 - pow(0.5, float(octaves) + 1.0))); // Scale values from 0 to 1
}

