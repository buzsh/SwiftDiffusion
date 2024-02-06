//
//  MainView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI

struct MainView: View {
  @ObservedObject var prompt: MainViewModel
  @State private var columnWidth: CGFloat = 200
  let minColumnWidth: CGFloat = 150
  
  let minSecondColumnWidth: CGFloat = 150
  
  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        // Column 1
        VStack {
          Form {
            PromptEditorView(label: "Positive Prompt", text: $prompt.positivePrompt)
            PromptEditorView(label: "Negative Prompt", text: $prompt.negativePrompt)
          }
          Spacer()
        }
        .frame(width: columnWidth)
        .padding()
        
        // Adjustable bar
        Divider()
          .frame(width: 10)
          .background(Color.primary.opacity(0.0001))
          .gesture(
            DragGesture()
              .onChanged { value in
                // Calculate the new width while ensuring it does not exceed the limits
                let maxColumnWidth = geometry.size.width - minSecondColumnWidth - 10 // Account for the divider's width
                let dragAdjustedWidth = columnWidth + value.translation.width
                columnWidth = min(max(dragAdjustedWidth, minColumnWidth), maxColumnWidth)
              }
          )
        
        // Column 2
        VStack {
          Text("Resizable column 2")
          Spacer()
        }
        .padding()
        .frame(minWidth: minSecondColumnWidth, maxWidth: .infinity) // Make column 2 take up the remaining space
      }
    }
    // Optional: Set a minimum width for the GeometryReader if needed
    .frame(minWidth: 300) // Adjust based on your app's minimum acceptable width
  }
}


#Preview("Left Prompt View") {
  let promptModel = MainViewModel()
  promptModel.positivePrompt = "sample, positive, prompt"
  promptModel.negativePrompt = "sample, negative, prompt"
  
  return MainView(prompt: promptModel)
}


extension NSTextView {
  open override var frame: CGRect {
    didSet {
      backgroundColor = .clear
      drawsBackground = true
    }
    
  }
}
