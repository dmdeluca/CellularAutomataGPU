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

  #if DEBUG
    let sharedCapturer = MTLCaptureManager.shared()
    let scope: MTLCaptureScope
  #endif  // DEBUG

  struct Constants {
    let width: Float32
    let height: Float32
  }

  init?(width: Int, height: Int) {
    var constants = Constants(width: Float32(width), height: Float32(height))
    let bufferLength = width * height * MemoryLayout<Float32>.stride
    guard
      let dvc = MTLCreateSystemDefaultDevice(),
      let cmq = dvc.makeCommandQueue(),
      let lib = dvc.makeDefaultLibrary(),
      let fun = lib.makeFunction(name: "cellStepGPU"),
      let cps = try? dvc.makeComputePipelineState(function: fun),
      let ibf = dvc.makeBuffer(length: bufferLength, options: .storageModeShared),
      let obf = dvc.makeBuffer(length: bufferLength, options: .storageModeShared),
      let cbf = dvc.makeBuffer(bytes: &constants, length: MemoryLayout<Constants>.stride)
    else {
      return nil
    }
    self.device = dvc
    self.commandQueue = cmq
    self.library = lib
    self.function = fun
    self.computePipelineState = cps
    self.inputBuffer = ibf
    self.outputBuffer = obf
    self.constantsBuffer = cbf
    self.maxThreadsPerThreadgroup = MTLSize(width: dvc.maxThreadsPerThreadgroup.width, height: 1, depth: 1)
    self.computeGridSize = MTLSize(width: width, height: height, depth: 1)
    #if DEBUG
      self.scope = sharedCapturer.makeCaptureScope(device: dvc)
      self.scope.label = "DAVID DEBUG"
      self.sharedCapturer.defaultCaptureScope = self.scope
    #endif  // DEBUG
  }
}

