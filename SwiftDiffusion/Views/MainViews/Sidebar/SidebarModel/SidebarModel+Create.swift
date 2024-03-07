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
