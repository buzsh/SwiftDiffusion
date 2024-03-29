//
//  PasteGenerationDataStatusBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/16/24.
//

import SwiftUI
import SwiftData

struct PasteGenerationDataStatusBar: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  @EnvironmentObject var currentPrompt: PromptModel
  @ObservedObject var userSettings = UserSettings.shared
  
  var generationDataInPasteboard: Bool
  var onPaste: (String) -> Void
  
  var body: some View {
    if sidebarModel.workspaceFolderContainsSelectedSidebarItem() {
      
      
      if generationDataInPasteboard || userSettings.alwaysShowPasteboardGenerationDataButton {
        HStack(alignment: .center) {
          
          Spacer()
          
          Button(action: {
            if let pasteboardContent = getPasteboardString() {
              onPaste(pasteboardContent)
            }
            sidebarModel.storeChangesOfSelectedSidebarItem(with: currentPrompt)
          }) {
            Text("Paste Generation Data")
            Image(systemName: SFSymbol.paste.name)
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
