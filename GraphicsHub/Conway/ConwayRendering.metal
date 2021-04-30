//
//  ConwayRendering.metal
//  GraphicsHub
//
//  Created by Noah Pikielny on 4/29/21.
//

#include <metal_stdlib>
using namespace metal;

int toIndex(int2 tid, int2 imageSize) {
    return tid.x + tid.y * imageSize.y;
}

kernel void conwayCalculate(uint2 tid [[thread_position_in_grid]],
                            constant int2 & cellCount [[buffer(0)]],
                            device int * cells [[buffer(1)]],
                            constant int * oldCells [[buffer(2)]]) {
    device int & cell = cells[toIndex(int2(tid), cellCount)];
    int count = 0;
    for (int x = -1; x < 2; x ++) {
        for (int y = -1; y < 2; y ++) {
            if (!(x == 0 && y == 0)) {
                int2 newCell = int2(x,y) + int2(tid);
                if (newCell.x > -1 && newCell.x < cellCount.x &&
                    newCell.y > -1 && newCell.y < cellCount.y) {
                    if (oldCells[toIndex(newCell, cellCount)] > 0) {
                        count += 1;
                    }
                }
            }
        }
    }
    int oldState = oldCells[toIndex(int2(tid), cellCount)];
    if (oldState == 0) {
        cell = count == 3 ? 1 : 0;
    } else {
        if (count == 2 || count == 3) {
            cell = oldState == 0 ? 1 : 2;
        } else {
            cell = 0;
        }
    }
    
//    device int & cell = cells[tid];
//    int count = 0;
//    for (int x = -1; x <= 1; x ++) {
//        for (int y = -1; y <= 1; y ++) {
//            if (!(x == 0 && y == 0)) {
////                int2 neighbor = int2(tid) + int2(x,y);
//                int2 neighbor = int2(tid) + int2(x,y);
//                if (neighbor.x >= 0 && neighbor.x < cellCount.x &&
//                    neighbor.y >= 0 && neighbor.y < cellCount.y) {
//                    if (oldCells[toIndex(neighbor, cellCount)] > 0) {
//                        count += 1;
//                    }
//                }
//            }
//        }
//    }
//    if (count < 2 || count > 3) {
//        cell = 0;
//    } else {
//        cell = (cell == 0) ? 1 : 2;
//    }
//    cell = 2;
//    if (oldCells[tid] == 0) {
//        cell = 1;
//    }else if (oldCells[tid] == 1) {
//        cell = 2;
//    } else {
//        cell = 0;
//    }
}

kernel void conwayDraw(uint2 tid [[thread_position_in_grid]],
                       constant int2 & imageSize[[buffer(0)]],
                       constant int2 & cellCount[[buffer(1)]],
                       constant int * cells [[buffer(2)]],
                       texture2d<float, access::read_write>Image) {
    float2 conversion = float2(cellCount) / float2(imageSize);
    int index = toIndex(int2(conversion * float2(tid)), cellCount);
    if (index < cellCount.x * cellCount.y) {
        int value = cells[index];
        if (value == 0) {
            Image.write(float4(float3(0),1), tid);
        } else if (value == 1) {
            Image.write(float4(1,0,0,1), tid);
        } else {
            Image.write(float4(1), tid);
        }
    } else {
        Image.write(float4(float3(0),1), tid);
    }
}

kernel void conwayCopy(uint2 tid [[thread_position_in_grid]],
                       constant int2 & cellCount [[buffer(0)]],
                       device int * cells [[buffer(1)]],
                       device int * oldCells [[buffer(2)]]) {
    int index = toIndex(int2(tid), cellCount);
    oldCells[index] = cells[index];
    cells[index] = 0;
}
