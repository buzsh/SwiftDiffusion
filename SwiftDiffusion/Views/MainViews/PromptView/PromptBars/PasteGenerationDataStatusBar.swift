//
//  PasteGenerationDataStatusBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/16/24.
//

import SwiftUI

struct PasteGenerationDataStatusBar: View {
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  @EnvironmentObject var currentPrompt: PromptModel
  @ObservedObject var userSettings = UserSettings.shared
  
  var generationDataInPasteboard: Bool
  var onPaste: (String) -> Void
  
  var body: some View {
    if let isWorkspaceItem = sidebarViewModel.selectedSidebarItem?.isWorkspaceItem, isWorkspaceItem {
      
      if generationDataInPasteboard || userSettings.alwaysShowPasteboardGenerationDataButton {
        HStack(alignment: .center) {
          
          Spacer()
          
          Button(action: {
            if let pasteboardContent = getPasteboardString() {
              onPaste(pasteboardContent)
            }
          }) {
            Text("Paste Generation Data")
            Image(systemName: "arrow.up.doc.on.clipboard")
          }
          .buttonStyle(.accessoryBar)
          
          
        }
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow))
      }
    }
    
  }
  
  func getPasteboardString() -> String? {
    return NSPasteboard.general.string(forType: .string)
  }
}
