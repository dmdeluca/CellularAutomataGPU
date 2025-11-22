//
//  ContentView.swift
//  CellularAutomataProject2
//
//  Created by David DeLuca on 11/21/25.
//

import Observation
import SwiftUI

struct ContentView: View {

  @State var model: GridModel?
  @State var isShowingAlert = false

  var body: some View {
    VStack {
      GeometryReader { geo in
        ZStack {
          if let model {
            Color.black.colorEffect(
              // Use a shader function to draw all of the cell colors.
              ShaderLibrary.cells(
                .floatArray(model.values),
                .float2(Float(model.width), Float(model.height)),
                .boundingRect
              )
            )
          }
        }
        .gesture(
          DragGesture(minimumDistance: 0)
            // Draw a small grid of cells when the user draws.
            .onChanged { value in
              model?.drawCells(at: value.location, in: geo)
            }
        )
        .alert(isPresented: $isShowingAlert) {
          Alert(
            title: Text("Oops."),
            message: Text("Failed to initialize life. Your device may be incompatible.")
          )
        }
        .onAppear {
          guard model == nil else { return }
          model = GridModel(width: Int(geo.size.width / 2), height: Int(geo.size.height / 2))
          if model?.error == .failedToInitializePipeline {
            isShowingAlert = true
          }
        }
      }
    }
    .ignoresSafeArea(.all)
  }
}

extension GridModel {
  func drawCells(at point: CGPoint, in bounds: GeometryProxy) {
    let normalizedPoint = CGPoint(x: point.x / bounds.size.width, y: point.y / bounds.size.height)
    let gridX = Int(floor(normalizedPoint.x * CGFloat(width)))
    let gridY = Int(floor(normalizedPoint.y * CGFloat(height)))
    let brushPadding = 2
    for xOffset in -brushPadding...brushPadding {
      for yOffset in -brushPadding...brushPadding {
        let offsetGridX = gridX + xOffset
        let offsetGridY = gridY + yOffset
        guard offsetGridX >= 0, offsetGridX < width, offsetGridY >= 0, offsetGridY < height else {
          return
        }
        values[offsetGridY * width + offsetGridX] = 1
      }
    }
  }
}

#Preview {
  ContentView()
}
