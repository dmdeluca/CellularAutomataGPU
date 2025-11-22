//
//  Grid.swift
//  CellularAutomataProject2
//
//  Created by David DeLuca on 11/22/25.
//

import Observation
import UIKit

/// The model that represents all of the values in the grid and executes a step function.
@Observable
class GridModel {

  enum Error: Swift.Error {
    case failedToInitializePipeline
  }

  /// The value of every cell in the grid.
  var values: [Float32]

  /// Any error that occurred during setup or execution.
  var error: Error?

  @ObservationIgnored let width: Int
  @ObservationIgnored let height: Int
  @ObservationIgnored private var displayLink: CADisplayLink?
  @ObservationIgnored private var pipeline: GPUComputePipeline?

  init(width: Int, height: Int) {
    self.width = width
    self.height = height
    values = .init(
      (0..<(width * height)).map { _ in
        Float32(Int.random(in: 0...1))
      }
    )

    // Set up the display link.
    let link = CADisplayLink(target: self, selector: #selector(stepGPU))
    link.add(to: .current, forMode: .default)
    link.preferredFramesPerSecond = 30
    self.displayLink = link

    // Set up the compute pipeline.
    self.pipeline = GPUComputePipeline(width: width, height: height)
    if pipeline == nil {
      self.error = .failedToInitializePipeline
    }
  }

  @objc public func stepGPU() {
    guard
      UIApplication.shared.applicationState == .active,
      let pipeline,
      let commandBuffer = pipeline.commandQueue.makeCommandBuffer(),
      let commandEncoder = commandBuffer.makeComputeCommandEncoder()
    else {
      return
    }

    pipeline.inputBuffer.copyFloat32(from: values)

    commandEncoder.setComputePipelineState(pipeline.computePipelineState)

    commandEncoder.setBuffers(
      [
        pipeline.inputBuffer,
        pipeline.outputBuffer,
        pipeline.constantsBuffer,
      ],
      offsets: [0, 0, 0],
      range: 0..<3
    )

    let threadgroupSize = MTLSize(width: 32, height: 16, depth: 1)
    let gridSize = MTLSize(width: width, height: height, depth: 1)
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

    values.copy(from: pipeline.outputBuffer)
  }
}
