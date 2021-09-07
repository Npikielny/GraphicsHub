//
//  ComplexRendering.h
//  GraphicsHub
//
//  Created by Noah Pikielny on 8/16/21.
//

#ifndef ComplexRendering_h
#define ComplexRendering_h

float4 julia(uint2 location, float2 origin, float2 c, float2 zoom, float scalingFactor, float3 colors[], int colorCount, int2 imageSize);
#endif /* ComplexRendering_h */
