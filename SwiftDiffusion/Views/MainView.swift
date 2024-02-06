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
  
  var body: some View {
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
        .background(Color.primary.opacity(0.1))
        .gesture(
          DragGesture()
            .onChanged { value in
              // Adjust column width with drag, ensuring it stays above the minimum
              columnWidth = max(columnWidth + value.translation.width, minColumnWidth)
            }
        )
      
      // Column 2
      VStack {
        Text("Resizable column 2")
        Spacer()
      }
      .padding()
      .frame(minWidth: 0, maxWidth: .infinity) // Make column 2 take up the remaining space
    }
    // Set a minimum width for the HStack if needed to prevent window resizing
    // .frame(minWidth: totalMinimumWidth)
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
