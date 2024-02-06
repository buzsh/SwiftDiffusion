//
//  MainView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI

enum FocusedField {
  case positivePrompt
  case negativePrompt
}

struct MainView: View {
  @ObservedObject var prompt: MainViewModel
  
  @FocusState private var focusedField: FocusedField?
  
  var body: some View {
    HStack {
      VStack {
        Form {
          PromptEditorView(label: "Positive Prompt", text: $prompt.positivePrompt)
          PromptEditorView(label: "Negative Prompt", text: $prompt.negativePrompt)
        }
        Spacer()
      }
      .padding()
      
      VStack {
        Text("Resizable column 2")
      }
      .padding()
    }
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
