//
//  File.swift
//  CellularAutomataProject2
//
//  Created by David DeLuca on 11/22/25.
//

import MetalKit
import Foundation

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
