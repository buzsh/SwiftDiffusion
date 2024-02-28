//
//  SidebarItemDeletionHandler.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import SwiftUI

struct SidebarItemDeletionHandler: View {
  @Environment(\.modelContext) var modelContext
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  @Binding var selectedItemID: UUID?
  @State var showDeletionAlert: Bool = false
  
  var body: some View {
    EmptyView()
      .onChange(of: sidebarViewModel.itemToDelete) {
        Debug.log("sidebarViewModel.itemToDelete TRIGGERED")
        if sidebarViewModel.itemToDelete != nil {
          showDeletionAlert = true
        }
      }
      .onChange(of: sidebarViewModel.workspaceItemToDeleteWithoutPrompt) {
        if sidebarViewModel.workspaceItemToDeleteWithoutPrompt != nil {
          deleteWorkspaceItemWithoutPrompt()
        }
      }
      .alert(isPresented: $showDeletionAlert) {
        Alert(
          title: Text("Are you sure you want to delete this item?"),
          primaryButton: .destructive(Text("Delete")) {
            deleteSavedItem()
          },
          secondaryButton: .cancel {
            sidebarViewModel.itemToDelete = nil
          }
        )
      }
  }
  
  private func deleteSavedItem() {
    if let itemToDelete = sidebarViewModel.itemToDelete {
      PreviewImageProcessingManager.shared.trashPreviewAndThumbnailAssets(for: itemToDelete, in: modelContext, withSoundEffect: true)
      deleteSidebarItem(sidebarViewModel.itemToDelete)
    }
  }
  
  private func deleteWorkspaceItemWithoutPrompt() {
    deleteSidebarItem(sidebarViewModel.workspaceItemToDeleteWithoutPrompt)
  }
  
  private func deleteSidebarItem(_ sidebarItem: SidebarItem?) {
    guard let itemToDelete = sidebarItem,
          let index = sidebarViewModel.allSidebarItems.firstIndex(where: { $0.id == itemToDelete.id }) else { return }
    
    modelContext.delete(sidebarViewModel.allSidebarItems[index])
    do {
      try modelContext.save()
    } catch {
      // Handle the error appropriately
    }
    sidebarViewModel.itemToDelete = nil
    sidebarViewModel.workspaceItemToDeleteWithoutPrompt = nil
    // Update the selectedItemID if necessary
  }
}
