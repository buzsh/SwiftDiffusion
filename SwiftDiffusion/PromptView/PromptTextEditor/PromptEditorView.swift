//
//  PromptEditorView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI

struct PromptEditorView: View {
  @EnvironmentObject var loraModelsManager: LoraModelsManager
  
  var label: String
  @Binding var text: String
  @FocusState private var isFocused: Bool
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text(label)
          .textCase(.uppercase)
          .font(.system(size: 11, weight: .bold, design: .rounded))
          .opacity(0.8)
        Spacer()
        if wordCount > 0 {
          Text("\(wordCount)")
            .opacity(0.5)
            .font(.system(size: 12, design: .monospaced))
        }
      }
      .padding(.horizontal, 8)
      
      
      TextEditor(text: $text)
        .frame(minHeight: 50, maxHeight: isFocused ? 170 : 90)
        .font(.system(.body, design: .monospaced))
        .padding(4)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
        )
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
      
      if !loraModelsManager.loraModels.isEmpty && isFocused {
        HStack {
          HalfMaxWidthView {}
          
          Menu {
            ForEach(loraModelsManager.loraModels, id: \.id) { lora in
              Button(lora.name) {
                let loraSyntax = "<lora:\(lora.alias):1>"
                text += (text.isEmpty ? "" : " ") + loraSyntax
              }
            }
          } label: {
            Label("Add LoRA", systemImage: "plus.circle")
          }
        }
        .frame(height: 30)
      }
      
    }
    .padding(.bottom, 10)
  }
  
  var wordCount: Int {
    let words = text.split { $0.isWhitespace || $0.isNewline }
    return words.count
  }
}

#Preview {
  let loraModelsManagerPreview = LoraModelsManager()
  loraModelsManagerPreview.loraModels = [
    LoraModel(name: "Some Lora", alias: "some_lora", path: "/path/to/some_lora"),
    LoraModel(name: "Another Lora", alias: "another_lora", path: "/path/to/another_lora")
  ]
  
  @State var promptText: String = "some, positive, prompt, text"
  return PromptEditorView(label: "Positive Prompt", text: $promptText)
    .frame(width: 400, height: 600)
    .environmentObject(loraModelsManagerPreview)
    //.environmentObject(CommonPreviews.previewLoraModelsManager)
}

extension CommonPreviews {
  static var previewLoraModelsManager: LoraModelsManager {
    let loraModelsManager = LoraModelsManager()
    loraModelsManager.loraModels = [
      LoraModel(name: "Some Lora", alias: "some_lora", path: "/path/to/some_lora"),
      LoraModel(name: "Another Lora", alias: "another_lora", path: "/path/to/another_lora")
    ]
    
    return loraModelsManager
  }
}

extension NSTextView {
  open override var frame: CGRect {
    didSet {
      backgroundColor = .clear
      drawsBackground = true
    }
    
  }
}
