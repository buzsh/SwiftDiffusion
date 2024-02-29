//
//  SidebarModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import Foundation
import SwiftData


class SidebarModel: ObservableObject {
  @Published var rootFolder: SidebarFolder? = nil
  @Published var workspaceFolder: SidebarFolder? = nil
  @Published var selectedItemID: UUID? = nil
  @Published var selectedSidebarItem: SidebarItem? = nil
  @Published var currentFolder: SidebarFolder? = nil
  @Published var currentlyGeneratingSidebarItem: SidebarItem? = nil
  
  /// SidebarItems that have been generated and can now be stored to the user's library.
  @Published var storableSidebarItems: [SidebarItem] = []
  
  @Published var modelNameButtonToggled: Bool = true
  @Published var noPreviewsItemButtonToggled: Bool = false
  @Published var smallPreviewsButtonToggled: Bool = true
  @Published var largePreviewsButtonToggled: Bool = false
  @Published var currentWidth: CGFloat = 240

  @Published var promptUserToConfirmDeletion: Bool = false
  
  func addToStorableSidebarItems(sidebarItem: SidebarItem, withImageUrls imageUrls: [URL]) {
    sidebarItem.imageUrls = imageUrls
    storableSidebarItems.append(sidebarItem)
  }
  
  @MainActor
  func moveStorableSidebarItemToFolder(sidebarItem: SidebarItem, withPrompt prompt: PromptModel, in modelContext: ModelContext) {
    storableSidebarItems.removeAll(where: { $0 == sidebarItem })
    currentFolder?.add(item: sidebarItem)
    workspaceFolder?.remove(item: sidebarItem)
    PreviewImageProcessingManager.shared.createImagePreviewsAndThumbnails(for: sidebarItem, in: modelContext)
    saveData(in: modelContext)
  }
  
  func removeSelectedWorkspaceItem() {
    if let workspaceFolder = workspaceFolder, let selectedSidebarItem = selectedSidebarItem {
      if workspaceFolder.items.contains(where: { $0.id == selectedSidebarItem.id }) {
        workspaceFolder.remove(item: selectedSidebarItem)
      }
    }
  }
  
  func deleteSelectedSidebarItemFromStorage(in modelContext: ModelContext) {
    if let selectedSidebarItem = selectedSidebarItem {
      PreviewImageProcessingManager.shared.trashPreviewAndThumbnailAssets(for: selectedSidebarItem, in: modelContext, withSoundEffect: true)
      
      debugLogCurrentFolderContents()
      
      if let currentFolder = currentFolder {
        Debug.log("[Delete] item: \(selectedSidebarItem.title), from currentFolder: \(currentFolder.name)")
      }
      
      currentFolder?.remove(item: selectedSidebarItem)
      saveData(in: modelContext)
      
      debugLogCurrentFolderContents()
    }
    
  }
  
  func debugLogCurrentFolderContents() {
    if let currentFolder = currentFolder {
      
      Debug.log("[Delete] Contents of currentFolder.items:")
      for item in currentFolder.items {
        Debug.log("  > \(item.title)")
      }
    }
  }
  
  func selectedItemIsWorkspaceItem() -> Bool {
    if let workspaceFolder = workspaceFolder, workspaceFolder.items.contains(where: { $0 == selectedSidebarItem }) {
      return true
    }
    return false
  }
  
  func selectedItemIsStorableItem() -> Bool {
    if let selectedSidebarItem = selectedSidebarItem, storableSidebarItems.contains(where: { $0 == selectedSidebarItem }) {
      return true
    }
    return false
  }
  
  func setCurrentFolder(to folder: SidebarFolder?) {
    if let folder = folder, folder != workspaceFolder  {
      currentFolder = folder
      selectedItemID = folder.id
    }
  }
  
  func setSelectedSidebarItem(to sidebarItem: SidebarItem?) {
    self.selectedSidebarItem = sidebarItem
    self.selectedItemID = sidebarItem?.id
  }
  
  /// Iterates through workspace items and populates savableSidebarItems with prompts that have previously generated media URLs associated with them.
  func updateStorableSidebarItemsInWorkspace() {
    if let workspaceItems = workspaceFolder?.items {
      for sidebarItem in workspaceItems {
        if sidebarItem.imageUrls.isEmpty == false {
          storableSidebarItems.append(sidebarItem)
        }
      }
    }
  }
}


extension SidebarModel {
  @MainActor func storeChangesOfSelectedSidebarItem(with prompt: PromptModel, in modelContext: ModelContext) {
    if let selectedSidebarItem = selectedSidebarItem {
      storeChanges(of: selectedSidebarItem, with: prompt, in: modelContext)
    }
  }
  
  @MainActor func storeChanges(of sidebarItem: SidebarItem, with prompt: PromptModel, in modelContext: ModelContext) {
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
      saveData(in: modelContext)
    }
  }
}

extension SidebarModel {
  func setSelectedSidebarItemTitle(_ title: String, in model: ModelContext) {
    //shouldCheckForNewSidebarItemToCreate = true
    if let isWorkspaceItem = selectedSidebarItem?.isWorkspaceItem, isWorkspaceItem {
      selectedSidebarItem?.title = title.count > Constants.Sidebar.titleLength ? String(title.prefix(Constants.Sidebar.titleLength)).appending("…") : title
    }
    saveData(in: model)
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
