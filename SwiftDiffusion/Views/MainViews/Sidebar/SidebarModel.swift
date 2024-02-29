//
//  SidebarModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import Foundation
import SwiftData

extension SidebarModel {
  
  @MainActor
  func storeChangesOfSelectedSidebarItem(for prompt: PromptModel, in model: ModelContext) {
    //shouldCheckForNewSidebarItemToCreate = true
    
    if selectedItemIsWorkspaceItem() {
      let mapModelData = MapModelData()
      let updatedPrompt = mapModelData.toStored(promptModel: prompt)
      
      if !selectedSidebarItemTitle(hasEqualTitleTo: updatedPrompt) && !prompt.positivePrompt.isEmpty {
        if let newTitle = updatedPrompt?.positivePrompt {
          selectedSidebarItem?.title = newTitle.count > Constants.Sidebar.titleLength ? String(newTitle.prefix(Constants.Sidebar.titleLength)).appending("…") : newTitle
        }
      }
      selectedSidebarItem?.prompt = updatedPrompt
      selectedSidebarItem?.timestamp = Date()
      saveData(in: model)
    }
  }
  private func selectedSidebarItemTitle(hasEqualTitleTo storedPromptModel: StoredPromptModel?) -> Bool {
    if let promptTitle = storedPromptModel?.positivePrompt, let sidebarItemTitle = selectedSidebarItem?.title {
      return promptTitle.prefix(Constants.Sidebar.titleLength) == sidebarItemTitle.prefix(Constants.Sidebar.titleLength)
    }
    return false
  }
}

extension SidebarModel {
  func findSidebarItem(by id: UUID?, in sidebarFolders: [SidebarFolder]) -> SidebarItem? {
    guard let id = id else { return nil }
    for folder in sidebarFolders {
      if let foundItem = folder.items.first(where: { $0.id == id }) {
        return foundItem
      }
    }
    return nil
  }
}

extension SidebarModel {
  func saveData(in model: ModelContext) {
    do {
      try model.save()
      Debug.log("[DD] Data successfully saved")
    } catch {
      Debug.log("[DD] Error saving context: \(error)")
    }
  }
}

extension SidebarModel {
  func ensureRootFolderExists(for folderQuery: [SidebarFolder], in modelContext: ModelContext) {
    if folderQuery.isEmpty {
      let newRootFolder = SidebarFolder(name: "Root", isRoot: true)
      modelContext.insert(newRootFolder)
      try? modelContext.save()
      Debug.log("[SidebarModel] Root folder created.")
      rootFolder = newRootFolder
    } else {
      Debug.log("[SidebarModel] Root folder exists.")
      rootFolder = folderQuery.first
    }
  }
  
  func ensureWorkspaceFolderExists(for folderQuery: [SidebarFolder], in modelContext: ModelContext) {
    if folderQuery.isEmpty {
      let newWorkspaceFolder = SidebarFolder(name: "Workspace", isWorkspace: true)
      modelContext.insert(newWorkspaceFolder)
      try? modelContext.save()
      Debug.log("[SidebarModel] Workspace folder created.")
      workspaceFolder = newWorkspaceFolder
    } else {
      Debug.log("[SidebarModel] Workspace folder exists.")
      workspaceFolder = folderQuery.first
    }
  }
}
