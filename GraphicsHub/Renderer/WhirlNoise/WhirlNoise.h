//
//  WhirlNoise.h
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/27/21.
//

#ifndef WhirlNoise_h
#define WhirlNoise_h

float3 chunkPoint(float3 coordinates, int3 chunkOffset, float3 chunkSize, int seed);
float whirlNoise(float3 coordinates, float3 chunkSize, int seed);
#endif /* WhirlNoise_h */
