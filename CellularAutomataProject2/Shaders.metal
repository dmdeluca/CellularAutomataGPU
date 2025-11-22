//
//  Shaders.metal
//  CellularAutomataProject2
//
//  Created by David DeLuca on 11/21/25.
//

#include <metal_stdlib>
using namespace metal;

[[stitchable]] half4
cells(float2 position, half4 currentValue, device const float *values, int,
      //                           device const half4 *colors, int,
      float2 rowsAndColumns, float4 boundingRect) {
  int iWidth = (int)rowsAndColumns.x;
  int xValue = (int)((position[0]) / boundingRect[2] * rowsAndColumns.x);
  int yValue = (int)((position[1]) / boundingRect[3] * rowsAndColumns.y);
  int index = yValue * iWidth + xValue;
  //  half4 color = half4(0,0,0,1);
  //  if (values[index] > 0.999) {
  //    color = colors[index];
  //  }
  half4 color = half4(values[index], values[index], values[index], 1);
  half4 finalColor = color;
  return finalColor;
}

kernel void cellStepGPU(const device float *inBuffer, device float *outBuffer,
                        const device float *constantsBuffer,
                        uint2 id [[thread_position_in_grid]]) {
  uint width = (uint)constantsBuffer[0];
  uint height = (uint)constantsBuffer[1];
  if (id.x < 0 || id.x >= width || id.y < 0 || id.y >= height) {
    return;
  }
  uint index = id.x + (id.y * width);
  uint centerX = id.x;
  uint centerY = id.y;
  uint upY = (id.y - 1 + height) % height;
  uint downY = (id.y + 1 + height) % height;
  uint leftX = (id.x - 1 + width) % width;
  uint rightX = (id.x + 1 + width) % width;

  int liveNeighborsCount = 0;
  liveNeighborsCount += (int)inBuffer[upY * width + leftX];
  liveNeighborsCount += (int)inBuffer[upY * width + centerX];
  liveNeighborsCount += (int)inBuffer[upY * width + rightX];
  liveNeighborsCount += (int)inBuffer[centerY * width + leftX];
  liveNeighborsCount += (int)inBuffer[centerY * width + rightX];
  liveNeighborsCount += (int)inBuffer[downY * width + leftX];
  liveNeighborsCount += (int)inBuffer[downY * width + centerX];
  liveNeighborsCount += (int)inBuffer[downY * width + rightX];

  int cellValue = (int)round(inBuffer[index]);
  if (cellValue) {
    if (liveNeighborsCount < 2 || liveNeighborsCount > 3) {
      cellValue = 0;
    }
  } else {
    if (liveNeighborsCount == 3) {
      cellValue = 1;
    }
  }
  outBuffer[index] = (float)cellValue;
}
