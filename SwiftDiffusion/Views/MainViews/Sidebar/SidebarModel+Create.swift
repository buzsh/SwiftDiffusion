//
//  SidebarModel+Create.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/4/24.
//

import Foundation

extension SidebarModel {
  
  func copySelectedSidebarItemToWorkspace() {
    guard let sidebarItem = selectedSidebarItem else { return }
    copyItemToWorkspace(sidebarItem)
  }
  
  private func copyItemToWorkspace(_ sidebarItem: SidebarItem) {
    if let clonedPrompt = sidebarItem.prompt {
      let clonedTitle = String(sidebarItem.title.prefix(Constants.Sidebar.titleLength))
      let clonedItem = SidebarItem(title: clonedTitle, imageUrls: [])
      clonedItem.prompt = clonedPrompt
      workspaceFolder.add(item: clonedItem)
      saveData(in: modelContext)
      cleanUpEmptyWorkspaceItems()
      setSelectedSidebarItem(to: clonedItem)
      addToStorableSidebarItems(sidebarItem: clonedItem, withImageUrls: sidebarItem.imageUrls)
    }
  }
  
}
