//
//  GPUComputePipeline.swift
//  CellularAutomataProject2
//
//  Created by David DeLuca on 11/22/25.
//

import MetalKit

struct GPUComputePipeline {

  let device: MTLDevice
  let library: MTLLibrary
  let function: MTLFunction
  let computePipelineState: MTLComputePipelineState
  let commandQueue: MTLCommandQueue

  let inputBuffer: MTLBuffer
  let outputBuffer: MTLBuffer
  let constantsBuffer: MTLBuffer

  let maxThreadsPerThreadgroup: MTLSize
  let computeGridSize: MTLSize

  let width: Int
  let height: Int

  #if DEBUG
    let sharedCapturer = MTLCaptureManager.shared()
    let scope: MTLCaptureScope
  #endif  // DEBUG

  struct Constants {
    let width: Float32
    let height: Float32
  }

  init?(width: Int, height: Int) {
    self.width = width
    self.height = height
    var constants = Constants(width: Float32(width), height: Float32(height))
    let bufferLength = width * height * MemoryLayout<Float32>.stride
    guard
      let device = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue(),
      let library = device.makeDefaultLibrary(),
      let cellStepFunction = library.makeFunction(name: "cellStepGPU"),
      let pipelineState = try? device.makeComputePipelineState(function: cellStepFunction),
      let inputBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared),
      let outputBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared),
      let constantsBuffer = device.makeBuffer(
        bytes: &constants,
        length: MemoryLayout<Constants>.stride
      )
    else {
      return nil
    }
    self.device = device
    self.commandQueue = commandQueue
    self.library = library
    self.function = cellStepFunction
    self.computePipelineState = pipelineState
    self.inputBuffer = inputBuffer
    self.outputBuffer = outputBuffer
    self.constantsBuffer = constantsBuffer
    self.maxThreadsPerThreadgroup = MTLSize(
      width: device.maxThreadsPerThreadgroup.width,
      height: 1,
      depth: 1
    )
    self.computeGridSize = MTLSize(width: width, height: height, depth: 1)
    #if DEBUG
      self.scope = sharedCapturer.makeCaptureScope(device: device)
      self.scope.label = "DAVID DEBUG"
      self.sharedCapturer.defaultCaptureScope = self.scope
    #endif  // DEBUG
  }

  func nextState(for currentState: [Float32]) -> [Float32] {
    guard
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let commandEncoder = commandBuffer.makeComputeCommandEncoder()
    else {
      return currentState
    }

    inputBuffer.copyFloat32(from: currentState)

    commandEncoder.setComputePipelineState(computePipelineState)

    commandEncoder.setBuffers(
      [
        inputBuffer,
        outputBuffer,
        constantsBuffer,
      ],
      offsets: [0, 0, 0],
      range: 0..<3
    )

    let maxThreadsWidth = device.maxThreadsPerThreadgroup.width
    let arbitraryThreadgroupHeight = 16
    let threadgroupSize = MTLSize(
      width: maxThreadsWidth / arbitraryThreadgroupHeight,
      height: arbitraryThreadgroupHeight,
      depth: 1
    )
    let gridSize = MTLSize(width: width, height: height, depth: 1)
    
    // Add 1 to each dimension to ensure the compute grid covers the entire cell grid.
    let threadgroupsPerGrid = MTLSize(
      width: gridSize.width / threadgroupSize.width + 1,
      height: gridSize.height / threadgroupSize.height + 1,
      depth: 1,
    )

    commandEncoder.dispatchThreadgroups(
      threadgroupsPerGrid,
      threadsPerThreadgroup: threadgroupSize,
    )
    commandEncoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    var newState = currentState
    newState.copy(from: outputBuffer)

    return newState
  }
}

extension MTLBuffer {
  func copyFloat32(from source: [Float32]) {
    contents().copyMemory(
      from: [Float32](source),
      byteCount: source.count * MemoryLayout<Float32>.stride
    )
  }
}

extension Array where Element: Strideable {
  mutating func copy(from buffer: MTLBuffer) {
    let bufferContents = buffer.contents().bindMemory(to: Element.self, capacity: count)
    let count = count
    self.withUnsafeMutableBufferPointer { bufferPointer in
      guard let baseAddress = bufferPointer.baseAddress else { return }
      baseAddress.initialize(from: bufferContents, count: count)
    }
  }
}
