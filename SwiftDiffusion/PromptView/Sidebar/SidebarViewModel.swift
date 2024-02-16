//
//  SidebarViewModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/14/24.
//

import SwiftUI
import SwiftData

class SidebarViewModel: ObservableObject {
  
  @Published var selectedSidebarItem: SidebarItem? = nil
  @Published var recentlyGeneratedAndArchivablePrompts: [SidebarItem] = []
  
  @Published var itemToDelete: SidebarItem? = nil
  @Published var workspaceItemToDeleteWithoutPrompt: SidebarItem? = nil
  
  @Published var allSidebarItems: [SidebarItem] = []
  @Published var savedItems: [SidebarItem] = []
  @Published var workspaceItems: [SidebarItem] = []
  
  @Published var savableSidebarItems: [SidebarItem] = []
  @Published var itemToSave: SidebarItem? = nil
  @Published var sidebarItemCurrentlyGeneratingOut: SidebarItem? = nil
  
  private func addToRecentlyGeneratedPromptArchivables(_ item: SidebarItem) {
    recentlyGeneratedAndArchivablePrompts.append(item)
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
  
  func saveSidebarItem(_ sidebarItem: SidebarItem, in model: ModelContext) -> SidebarItem {
    model.insert(sidebarItem)
    saveData(in: model)
    return sidebarItem
  }
  
  @MainActor
  func createSidebarItemAndSaveToData(title: String = "New Prompt", appPrompt: AppPromptModel, imageUrls: [URL], in model: ModelContext) -> SidebarItem {
    let newSidebarItem = SidebarItem(title: title, timestamp: Date(), imageUrls: imageUrls, prompt: appPrompt)
    return saveSidebarItem(newSidebarItem, in: model)
  }
  
  func saveData(in model: ModelContext) {
    do {
      try model.save()
    } catch {
      Debug.log("Error saving context: \(error)")
    }
  }
  
  @MainActor
  func savePromptToData(title: String, prompt: PromptModel, imageUrls: [URL], in model: ModelContext) {
    let mapping = ModelDataMapping()
    let promptData = mapping.toArchive(promptModel: prompt)
    let newItem = SidebarItem(title: title, timestamp: Date(), imageUrls: imageUrls, prompt: promptData)
    Debug.log("savePromptToData prompt.SdModel: \(String(describing: prompt.selectedModel?.sdModel?.title))")
    model.insert(newItem)
    saveData(in: model)
  }
  
}
