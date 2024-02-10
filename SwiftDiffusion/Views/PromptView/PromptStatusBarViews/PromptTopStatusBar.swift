//
//  PromptTopStatusBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct PromptTopStatusBar: View {
  var userSettings: UserSettingsModel
  var generationDataInPasteboard: Bool
  var onPaste: (String) -> Void // Closure to handle paste action
  
  var body: some View {
    if generationDataInPasteboard || userSettings.alwaysShowPasteboardGenerationDataButton {
      HStack {
        Button("Paste Generation Data") {
          if let pasteboardContent = getPasteboardString() {
            onPaste(pasteboardContent)
          }
        }
        .buttonStyle(.accessoryBar)
        .padding(.leading, 10)
        
        Spacer()
      }
      .frame(height: 24)
      .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow)) // Assuming VisualEffectBlurView is defined elsewhere
    }
  }
  
  func getPasteboardString() -> String? {
    return NSPasteboard.general.string(forType: .string)
  }
}

#Preview {
  CommonPreviews.promptView
}

#Preview {
  let mockParseAndSetPromptData: (String) -> Void = { pasteboardContent in
      print("Pasteboard content: \(pasteboardContent)")
  }
  return PromptTopStatusBar(
      userSettings: UserSettingsModel.preview(),
      generationDataInPasteboard: true,
      onPaste: mockParseAndSetPromptData
  )
}
