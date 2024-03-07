//
//  PromptControlBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct PromptControlBarView: View {
  @EnvironmentObject var sidebarModel: SidebarModel
  @State private var isPromptControlBarVisible: Bool = false
  
  var body: some View {
    VStack(spacing: 0) {
      if isPromptControlBarVisible {
        PromptControlBar()
          .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    
    
    .onChange(of: sidebarModel.selectedSidebarItem) {
      updatePromptControlBarVisibility()
    }
    .onChange(of: sidebarModel.updateControlBarView) {
      updatePromptControlBarVisibility()
      sidebarModel.updateControlBarView = false
    }
  }
  
  private func updatePromptControlBarVisibility() {
    if isPromptControlBarVisible != (sidebarModel.selectedSidebarItem?.title != "New Prompt") {
      withAnimation(.easeInOut(duration: 0.2)) {
        isPromptControlBarVisible.toggle()
      }
    }
  }
}


struct PromptControlBar: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarModel: SidebarModel
  @ObservedObject var userSettings = UserSettings.shared
  
  @State var showingDeleteSelectedSidebarItemConfirmationAlert: Bool = false
  
  @State private var isWorkspaceItem: Bool = false
  @State private var isStorableSidebarItem: Bool = false
  
  private var workspaceItemBar: some View {
    HStack {
      Button(action: {
        sidebarModel.deleteSelectedWorkspaceItem()
        /*
        if let sidebarItem = sidebarModel.selectedSidebarItem {
          sidebarModel.deleteWorkspaceItem(sidebarItem)
        }
         */
        
      }) {
        Image(systemName: "xmark")
        Text("Close")
      }
      
      Spacer()
      
      if isStorableSidebarItem {
        Button(action: {
          sidebarModel.saveWorkspaceItem(withPrompt: currentPrompt)
          sidebarModel.moveWorkspaceItemToCurrentFolder()
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
    HStack {
      Button(action: {
        showingDeleteSelectedSidebarItemConfirmationAlert = true
      }) {
        Image(systemName: "trash")
        Text("Delete")
      }
      .alert(isPresented: $showingDeleteSelectedSidebarItemConfirmationAlert) {
        Alert(
          title: Text("Are you sure you want to delete this item?"),
          primaryButton: .destructive(Text("Delete")) {
            sidebarModel.deleteSelectedStoredItemFromCurrentFolder()
          },
          secondaryButton: .cancel()
        )
      }
      
      Spacer()
      
      Button(action: {
        withAnimation {
          sidebarModel.copySelectedSidebarItemToWorkspace()
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
      isWorkspaceItem = sidebarModel.workspaceFolderContainsSelectedSidebarItem()
      
      if let selectedSidebarItem = sidebarModel.selectedSidebarItem {
        isStorableSidebarItem = sidebarModel.storableSidebarItems.contains(where: { $0.id == selectedSidebarItem.id })
      }
    }
    .onChange(of: sidebarModel.workspaceFolderContainsSelectedSidebarItem()) {
      updateActionBarButtonItems()
      updateSavableSidebarItemState()
    }
    
    .onChange(of: sidebarModel.selectedSidebarItem) {
      updateActionBarButtonItems()
      updateSavableSidebarItemState()
    }
    .onChange(of: sidebarModel.selectedSidebarItem?.imageUrls) {
      updateSavableSidebarItemState()
    }
  }
  
  private func updateActionBarButtonItems() {
    if isWorkspaceItem != sidebarModel.workspaceFolderContainsSelectedSidebarItem() {
      withAnimation(.easeInOut(duration: 0.2)) {
        isWorkspaceItem.toggle()
      }
    }
  }
  
  private func updateSavableSidebarItemState() {
     if isStorableSidebarItem != sidebarModel.selectedItemIsStorableItem() {
        withAnimation(.easeInOut(duration: 0.2)) {
          isStorableSidebarItem.toggle()
        }
      }
  }
  
}
