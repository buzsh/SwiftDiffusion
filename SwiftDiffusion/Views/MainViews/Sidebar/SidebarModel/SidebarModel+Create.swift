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
    newWorkspaceItem.prompt = StoredPromptModel()
    create(sidebarItem: newWorkspaceItem, in: workspaceFolder)
  }
  
  func createNewWorkspaceItem(withPrompt prompt: StoredPromptModel) {
    let title = prompt.positivePrompt.truncatingToLength(Constants.Sidebar.titleLength)
    let newWorkspaceItem = SidebarItem(title: title, imageUrls: [])
    newWorkspaceItem.prompt = prompt
    cleanUpEmptyWorkspaceItems()
    create(sidebarItem: newWorkspaceItem, in: workspaceFolder)
  }
  
  private func create(sidebarItem: SidebarItem, in folder: SidebarFolder) {
    folder.add(item: sidebarItem)
    saveData(in: modelContext)
    setSelectedSidebarItem(to: sidebarItem)
  }
}
