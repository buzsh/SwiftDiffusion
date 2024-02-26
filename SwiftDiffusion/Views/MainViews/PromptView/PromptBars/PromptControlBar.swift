//
//  PromptControlBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct PromptControlBarView: View {
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  @State private var isPromptControlBarVisible: Bool = false
  
  var body: some View {
    VStack(spacing: 0) {
      if isPromptControlBarVisible {
        PromptControlBar()
          .transition(.move(edge: .top).combined(with: .opacity))
          .animation(.easeInOut(duration: 0.3), value: isPromptControlBarVisible)
      }
    }
    .onChange(of: sidebarViewModel.selectedSidebarItem) {
      updatePromptControlBarVisibility()
    }
  }
  
  private func updatePromptControlBarVisibility() {
    if isPromptControlBarVisible != (sidebarViewModel.selectedSidebarItem?.title != "New Prompt") {
      withAnimation(.easeInOut(duration: 0.3)) {
        isPromptControlBarVisible.toggle()
      }
    }
  }
}


struct PromptControlBar: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  @ObservedObject var userSettings = UserSettings.shared
  
  @State private var isWorkspaceItem: Bool = false
  @State private var isSavableSidebarItem: Bool = false
  
  private var workspaceItemBar: some View {
    Group {
      Button(action: {
        sidebarViewModel.queueWorkspaceItemForDeletion()
      }) {
        Image(systemName: "xmark")
        Text("Close")
      }
      
      Spacer()
      
      if isSavableSidebarItem {
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
      
      if let selectedSidebarItem = sidebarViewModel.selectedSidebarItem {
        isSavableSidebarItem = sidebarViewModel.savableSidebarItems.contains(where: { $0.id == selectedSidebarItem.id })
      }
    }
    .onChange(of: sidebarViewModel.selectedSidebarItem) {
      updateActionBarButtonItems()
      updateSavableSidebarItemState()
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
  
  private func updateSavableSidebarItemState() {
    if let selectedSidebarItem = sidebarViewModel.selectedSidebarItem {
      if isSavableSidebarItem != sidebarViewModel.savableSidebarItems.contains(where: { $0.id == selectedSidebarItem.id }) {
        withAnimation(.easeInOut(duration: 0.2)) {
          isSavableSidebarItem.toggle()
        }
      }
    }
  }
  
}
