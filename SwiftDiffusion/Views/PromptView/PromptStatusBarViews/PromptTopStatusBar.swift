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
  var onPaste: (String) -> Void // Closure to handle paste action
  
  var body: some View {
    
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
            copyToClipboard(currentPrompt.getSharablePromptMetadata())
          }) {
            Image(systemName: "doc.on.clipboard")
          }
          .buttonStyle(BorderlessButtonStyle())
          .buttonStyle(.accessoryBar)
        }
      }
      .padding(.horizontal, 12)
      .frame(height: 24)
      .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow)) // Assuming VisualEffectBlurView is defined elsewhere
  }
  
  func getPasteboardString() -> String? {
    return NSPasteboard.general.string(forType: .string)
  }
  
  func copyToClipboard(_ string: String) {
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(string, forType: .string)
  }
}

#Preview {
  CommonPreviews.promptView
}

/*
#Preview {
  let mockParseAndSetPromptData: (String) -> Void = { pasteboardContent in
      print("Pasteboard content: \(pasteboardContent)")
  }
  let promptModelPreview: PromptModel
  return PromptTopStatusBar(
      generationDataInPasteboard: true,
      onPaste: mockParseAndSetPromptData
  )
}
*/
