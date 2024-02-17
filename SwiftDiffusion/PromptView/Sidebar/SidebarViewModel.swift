//
//  SidebarViewModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/14/24.
//

import SwiftUI
import SwiftData

extension Constants {
  struct Sidebar {
    static let itemTitleLength: Int = 60
  }
}

class SidebarViewModel: ObservableObject {
  
  @Published var selectedSidebarItem: SidebarItem? = nil
  
  @Published var itemToDelete: SidebarItem? = nil
  @Published var workspaceItemToDeleteWithoutPrompt: SidebarItem? = nil
  
  @Published var allSidebarItems: [SidebarItem] = []
  @Published var savedItems: [SidebarItem] = []
  @Published var workspaceItems: [SidebarItem] = []
  
  @Published var savableSidebarItems: [SidebarItem] = []
  @Published var itemToSave: SidebarItem? = nil
  @Published var sidebarItemCurrentlyGeneratingOut: SidebarItem? = nil
  
  @Published var newlyCreatedSidebarWorkspaceItemIdToSelect: UUID?
  
  @MainActor
  func storeChangesOfSelectedSidebarItem(for prompt: PromptModel, in model: ModelContext) {
    if let isWorkspaceItem = selectedSidebarItem?.isWorkspaceItem, isWorkspaceItem {
      let mapModelData = MapModelData()
      let updatedPrompt = mapModelData.toArchive(promptModel: prompt)
      
      if !selectedSidebarItemTitle(hasEqualTitleTo: updatedPrompt) && !prompt.positivePrompt.isEmpty {
        if let newTitle = updatedPrompt?.positivePrompt {
          selectedSidebarItem?.title = newTitle.count > 45 ? String(newTitle.prefix(45)).appending("…") : newTitle
        }
      }
      selectedSidebarItem?.prompt = updatedPrompt
      selectedSidebarItem?.timestamp = Date()
      saveData(in: model)
    }
  }
  
  private func selectedSidebarItemTitle(hasEqualTitleTo storedPromptModel: StoredPromptModel?) -> Bool {
    if let promptTitle = storedPromptModel?.positivePrompt, let sidebarItemTitle = selectedSidebarItem?.title {
      return promptTitle.prefix(Constants.Sidebar.itemTitleLength) == sidebarItemTitle.prefix(Constants.Sidebar.itemTitleLength)
    }
    return false
  }
  
  func queueSelectedSidebarItemForDeletion() {
    itemToDelete = selectedSidebarItem
  }
  
  func queueWorkspaceItemForDeletion() {
    workspaceItemToDeleteWithoutPrompt = selectedSidebarItem
  }
  
  func queueSelectedSidebarItemForSaving() {
    if let queuedItem = selectedSidebarItem {
      itemToSave = queuedItem
      removeSidebarItemFromSavableQueue(sidebarItem: queuedItem)
    }
  }
  
  private func removeSidebarItemFromSavableQueue(sidebarItem: SidebarItem) {
    if savableSidebarItems.contains(where: { $0.id == sidebarItem.id }) {
      savableSidebarItems.removeAll { $0.id == sidebarItem.id }
    }
  }
  
  func prepareGeneratedPromptForSaving(sideBarItem: SidebarItem, imageUrls: [URL]) {
    sideBarItem.imageUrls = imageUrls
    savableSidebarItems.append(sideBarItem)
  }
  
  @MainActor
  func createSidebarItemAndSaveToData(title: String = "New Prompt", storedPrompt: StoredPromptModel, imageUrls: [URL], isWorkspaceItem: Bool, in model: ModelContext) -> SidebarItem {
    let newSidebarItem = SidebarItem(title: title, timestamp: Date(), imageUrls: imageUrls, isWorkspaceItem: isWorkspaceItem, prompt: storedPrompt)
    return saveSidebarItem(newSidebarItem, in: model)
  }
  
  func saveSidebarItem(_ sidebarItem: SidebarItem, in model: ModelContext) -> SidebarItem {
    model.insert(sidebarItem)
    saveData(in: model)
    return sidebarItem
  }
  
  func saveData(in model: ModelContext) {
    do {
      try model.save()
    } catch {
      Debug.log("Error saving context: \(error)")
    }
  }
}

extension SidebarViewModel {
  @MainActor
  func createNewPromptSidebarWorkspaceItem(in model: ModelContext) -> SidebarItem? {
    let mapModelData = MapModelData()
    let newPrompt = PromptModel()
    guard let storedPromptModel = mapModelData.toArchive(promptModel: newPrompt) else { return nil }
    let imageUrls: [URL] = []
    let newSidebarItem = createSidebarItemAndSaveToData(title: "New Prompt", storedPrompt: storedPromptModel, imageUrls: imageUrls, isWorkspaceItem: true, in: model)
    return newSidebarItem
  }
}
