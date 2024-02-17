//
//  PromptTopStatusBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct PromptTopStatusBar: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  @ObservedObject var userSettings = UserSettings.shared
  
  var generationDataInPasteboard: Bool
  var onPaste: (String) -> Void
  
  var body: some View {
    HStack(alignment: .center) {
      
      if sidebarViewModel.selectedSidebarItem?.title != "New Prompt" {
        
        if let isWorkspaceItem = sidebarViewModel.selectedSidebarItem?.isWorkspaceItem, isWorkspaceItem {
          Button(action: {
            sidebarViewModel.queueWorkspaceItemForDeletion()
          }) {
            Image(systemName: "xmark")
            Text("Close")
          }
          .buttonStyle(.accessoryBar)
        } else {
          Button(action: {
            sidebarViewModel.queueSelectedSidebarItemForDeletion()
          }) {
            Image(systemName: "trash")
            Text("Delete")
          }
          .buttonStyle(.accessoryBar)
        }
        
      }
      
      Spacer()
      
      if generationDataInPasteboard || userSettings.alwaysShowPasteboardGenerationDataButton {
        Button(action: {
          if let pasteboardContent = getPasteboardString() {
            onPaste(pasteboardContent)
          }
        }) {
          Image(systemName: "arrow.up.doc.on.clipboard")
          Text("Paste Generation Data")
        }
        .buttonStyle(.accessoryBar)
      }
      
      if sidebarViewModel.selectedSidebarItem?.title != "New Prompt" {
        
        if let isWorkspaceItem = sidebarViewModel.selectedSidebarItem?.isWorkspaceItem, isWorkspaceItem {
          Spacer()
          
          if let selectedSidebarItem = sidebarViewModel.selectedSidebarItem,
             sidebarViewModel.savableSidebarItems.contains(where: { $0.id == selectedSidebarItem.id }) {
            Button(action: {
              sidebarViewModel.queueSelectedSidebarItemForSaving()
            }) {
              Image(systemName: "square.and.arrow.down")
              Text("Save Generated Prompt")
            }
            .buttonStyle(.accessoryBar)
          }
        } else {
          
          Button(action: {
            
            if let selectedSidebarItem = sidebarViewModel.selectedSidebarItem, let promptCopy = selectedSidebarItem.prompt {
              let newItemTitle = String(selectedSidebarItem.title.prefix(Constants.Sidebar.itemTitleLength))
              let newWorkspaceSidebarItem = sidebarViewModel.createSidebarItemAndSaveToData(title: newItemTitle, storedPrompt: promptCopy, imageUrls: selectedSidebarItem.imageUrls, isWorkspaceItem: true, in: modelContext)
              newWorkspaceSidebarItem.timestamp = selectedSidebarItem.timestamp
              sidebarViewModel.newlyCreatedSidebarWorkspaceItemIdToSelect = newWorkspaceSidebarItem.id
            }
          }) {
            Image(systemName: "tray.and.arrow.up")
            Text("Copy to Workspace")
          }
          .buttonStyle(.accessoryBar)
        }
        
      }
      
    }
    .padding(.horizontal, 12)
    .frame(height: 30)
    .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow))
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
