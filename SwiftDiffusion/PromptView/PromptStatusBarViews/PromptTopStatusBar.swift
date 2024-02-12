//
//  PromptTopStatusBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct PromptTopStatusBar: View {
  @EnvironmentObject var currentPrompt: PromptModel
  @ObservedObject var userSettings = UserSettings.shared
  
  var generationDataInPasteboard: Bool
  var onPaste: (String) -> Void
  
  var body: some View {
    if generationDataInPasteboard || userSettings.alwaysShowPasteboardGenerationDataButton || currentPrompt.selectedModel != nil {
      
      HStack {
        if generationDataInPasteboard || userSettings.alwaysShowPasteboardGenerationDataButton {
          Button("Paste Generation Data") {
            if let pasteboardContent = getPasteboardString() {
              onPaste(pasteboardContent)
            }
          }
          .buttonStyle(.accessoryBar)
        }
        
        Spacer()
        
        if currentPrompt.selectedModel != nil {
          Button(action: {
            currentPrompt.copyMetadataToClipboard()
          }) {
            Image(systemName: "doc.on.clipboard")
          }
          .buttonStyle(BorderlessButtonStyle())
          .buttonStyle(.accessoryBar)
        }
      }
      .padding(.horizontal, 12)
      .frame(height: 24)
      .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow))
    }
  }
  
  func getPasteboardString() -> String? {
    return NSPasteboard.general.string(forType: .string)
  }
  
}

#Preview("PromptView") {
  CommonPreviews.promptTopStatusBarView
}

extension CommonPreviews {
  
  @MainActor
  static var promptTopStatusBarView: some View {
    let promptModelPreview = PromptModel()
    promptModelPreview.positivePrompt = "sample, positive, prompt"
    promptModelPreview.negativePrompt = "sample, negative, prompt"
    
    promptModelPreview.selectedModel = ModelItem(name: "some_model.safetensor", type: .python, url: URL(fileURLWithPath: "/"), isDefaultModel: false)
    
    let modelManagerViewModel = ModelManagerViewModel()
    
    return PromptView(
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .environmentObject(promptModelPreview)
    .environmentObject(modelManagerViewModel)
    .frame(width: 400, height: 600)
  }
}

#Preview("TopStatusBar") {
  let mockParseAndSetPromptData: (String) -> Void = { pasteboardContent in
    print("Pasteboard content: \(pasteboardContent)")
  }
  let promptModelPreview = PromptModel()
  promptModelPreview.positivePrompt = "sample, positive, prompt"
  promptModelPreview.negativePrompt = "sample, negative, prompt"
  promptModelPreview.selectedModel = ModelItem(name: "some_model.safetensor", type: .python, url: URL(fileURLWithPath: "/"), isDefaultModel: false)
  
  return PromptTopStatusBar(
    generationDataInPasteboard: true,
    onPaste: mockParseAndSetPromptData
  )
  .environmentObject(promptModelPreview)
  .frame(width: 400)
}
