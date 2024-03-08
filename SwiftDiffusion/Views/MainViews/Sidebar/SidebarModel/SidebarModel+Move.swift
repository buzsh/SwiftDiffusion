//
//  SidebarModel+Move.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/7/24.
//

import Foundation

// MARK: User Gesture Move
extension SidebarModel {
  func moveSidebarItem(withId sidebarItemId: UUID, toFolderWithId folderId: UUID) {
    queueMovableSidebarItemID = sidebarItemId
    queueDestinationFolderID = folderId
    beginMovableSidebarItemQueue = true
  }
}

// MARK: Move on Action
extension SidebarModel {
  func moveWorkspaceItemToCurrentFolder() {
    guard let selectedSidebarItem = selectedSidebarItem,
          let currentFolder = currentFolder
    else { return }
    
    storableSidebarItems.removeAll(where: { $0 == selectedSidebarItem })
    PreviewImageProcessingManager.shared.createImagePreviewsAndThumbnails(for: selectedSidebarItem, in: modelContext)
    selectedSidebarItem.timestamp = Date()
    move(sidebarItem: selectedSidebarItem, from: workspaceFolder, to: currentFolder)
  }
  
  func moveSelectedSidebarItem(to folder: SidebarFolder) {
    guard let selectedSidebarItem = selectedSidebarItem,
          let currentFolder = currentFolder
    else { return }
    
    move(sidebarItem: selectedSidebarItem, from: currentFolder, to: folder)
  }
  
  private func move(sidebarItem: SidebarItem, from currentParent: SidebarFolder, to targetParent: SidebarFolder) {
    targetParent.add(item: sidebarItem)
    currentParent.remove(item: sidebarItem)
    saveData(in: modelContext)
  }
}
