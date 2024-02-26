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
  
  @State private var isWorkspaceItem: Bool = false
  
  private var workspaceItemBar: some View {
    Group {
      Button(action: {
        sidebarViewModel.queueWorkspaceItemForDeletion()
      }) {
        Image(systemName: "xmark")
        Text("Close")
      }
      
      Spacer()
      
      if let selectedSidebarItem = sidebarViewModel.selectedSidebarItem,
         sidebarViewModel.savableSidebarItems.contains(where: { $0.id == selectedSidebarItem.id }) {
        Button(action: {
          sidebarViewModel.queueSelectedSidebarItemForSaving()
        }) {
          Text("Save Generated Prompt")
          Image(systemName: "square.and.arrow.down")
        }
      }
    }
    .buttonStyle(.accessoryBar)
    .transition(.opacity)
  }
  
  private var storedItemBar: some View {
    Group {
      Button(action: {
          sidebarViewModel.queueSelectedSidebarItemForDeletion()
      }) {
        Image(systemName: "trash")
        Text("Delete")
      }
      
      Spacer()
      
      Button(action: {
        if let selectedSidebarItem = sidebarViewModel.selectedSidebarItem, let promptCopy = selectedSidebarItem.prompt {
          let newItemTitle = String(selectedSidebarItem.title.prefix(Constants.Sidebar.itemTitleLength))
          let newWorkspaceSidebarItem = sidebarViewModel.createSidebarItemAndSaveToData(title: newItemTitle, storedPrompt: promptCopy, imageUrls: selectedSidebarItem.imageUrls, isWorkspaceItem: true, in: modelContext)
          newWorkspaceSidebarItem.timestamp = selectedSidebarItem.timestamp
          sidebarViewModel.newlyCreatedSidebarWorkspaceItemIdToSelect = newWorkspaceSidebarItem.id
        }
      }) {
        Text("Copy to Workspace")
        Image(systemName: "tray.and.arrow.up")
      }
    }
    .buttonStyle(.accessoryBar)
    .transition(.opacity)
  }
  
  var body: some View {
    HStack(alignment: .center) {
      if isWorkspaceItem {
        workspaceItemBar
      } else {
        storedItemBar
      }
    }
    .padding(.horizontal, 12)
    .frame(height: 30)
    .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow))
    .onAppear {
      isWorkspaceItem = sidebarViewModel.selectedSidebarItem?.isWorkspaceItem ?? false
    }
    .onChange(of: sidebarViewModel.selectedSidebarItem) {
      updateActionBarButtonItems()
    }
  }
  
  private func updateActionBarButtonItems() {
    if let selectedSidebarItemIsWorkspaceItem = sidebarViewModel.selectedSidebarItem?.isWorkspaceItem,
    isWorkspaceItem != selectedSidebarItemIsWorkspaceItem {
      withAnimation(.easeInOut(duration: 0.2)) {
        isWorkspaceItem.toggle()
      }
    }
  }
  
}

/*
#Preview("PromptView") {
  CommonPreviews.promptTopStatusBarView
}

extension CommonPreviews {
  
  @MainActor
  static var promptTopStatusBarView: some View {
    let promptModelPreview = PromptModel()
    promptModelPreview.positivePrompt = "sample, positive, prompt"
    promptModelPreview.negativePrompt = "sample, negative, prompt"
    
    promptModelPreview.selectedModel = CheckpointModel(name: "some_model.safetensor", path: "/path/to/checkpoint", type: .python)
    
    let checkpointsManagerPreview = CheckpointsManager()
    
    return PromptView(
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .environmentObject(promptModelPreview)
    .environmentObject(checkpointsManagerPreview)
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
  promptModelPreview.selectedModel = CheckpointModel(name: "some_model.safetensor", path: "/path/to/checkpoint", type: .python)
  
  return PromptTopStatusBar(
    generationDataInPasteboard: true,
    onPaste: mockParseAndSetPromptData
  )
  .environmentObject(promptModelPreview)
  .frame(width: 400)
}
*/
