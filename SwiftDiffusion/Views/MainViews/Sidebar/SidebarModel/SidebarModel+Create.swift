//
//  SidebarModel+Create.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/4/24.
//

import Foundation

extension SidebarModel {
  func createNewWorkspaceItem() {
    let newWorkspaceItem = SidebarItem(title: "", imageUrls: [])
    newWorkspaceItem.prompt = StoredPromptModel(isWorkspaceItem: true)
    create(sidebarItem: newWorkspaceItem, in: workspaceFolder)
  }
  
  private func create(sidebarItem: SidebarItem, in folder: SidebarFolder) {
    folder.add(item: sidebarItem)
    saveData(in: modelContext)
    setSelectedSidebarItem(to: sidebarItem)
  }
}
  
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
    }
  }
  
}
