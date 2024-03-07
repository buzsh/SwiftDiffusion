//
//  SidebarModel+Move.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/7/24.
//

import Foundation

extension SidebarModel {
  func moveWorkspaceItemToCurrentFolder() {
    guard let selectedSidebarItem = selectedSidebarItem,
          let currentFolder = currentFolder
    else { return }
    
    storableSidebarItems.removeAll(where: { $0 == selectedSidebarItem })
    PreviewImageProcessingManager.shared.createImagePreviewsAndThumbnails(for: selectedSidebarItem, in: modelContext)
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
