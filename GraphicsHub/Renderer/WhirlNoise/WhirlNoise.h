//
//  WhirlNoise.h
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/27/21.
//

#ifndef WhirlNoise_h
#define WhirlNoise_h

float3 chunkPoint(float3 coordinates, int3 chunkOffset, float3 chunkSize, int seed, float density);
float whirlNoise(float3 coordinates, float3 chunkSize, int seed, float scaling, float density);
float3 whirlNormal(float3 coordinates, float3 chunkSize, int seed);
float smoothWhirlNoise(float3 coordinates, float3 chunkSize, int seed, float blendingStrength);
float whirlNoise(float3 coordinates, float3 chunkSize[], int seed[], float scaling[], float density[], int iterations);
float3 smoothWhirlNormal(float3 coordinates, float3 chunkSize, int seed, float blendingStrength);
#endif /* WhirlNoise_h */
