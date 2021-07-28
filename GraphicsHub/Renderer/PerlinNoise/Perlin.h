//
//  Perlin.h
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/25/21.
//

#ifndef Perlin_h
#define Perlin_h

float perlin (int2 position, int sideLength, int octaves, int noiseX, int noiseZ, int noiseSeed, float zoom);
float perlin2 (int2 position,
                     int sideLength, // Max Chunk Size
                     int octaves,
                     int noiseX,
                     int noiseZ,
                     int noiseSeed,
                     float zoom,
               float4 v);
#endif /* Perlin_h */
