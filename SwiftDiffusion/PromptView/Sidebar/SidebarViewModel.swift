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
  
  @Published var workspacePrompts: [SidebarItem] = []
  
  
  
  private func addToRecentlyGeneratedPromptArchivables(_ item: SidebarItem) {
    recentlyGeneratedAndArchivablePrompts.append(item)
  }
  
  func queueSelectedSidebarItemForDeletion() {
    itemToDelete = selectedSidebarItem
  }
  
  /// Save most recently generated prompt archivable to the sidebar
  func saveMostRecentArchivablePromptToSidebar(in model: ModelContext) {
    if let latestGenerated = recentlyGeneratedAndArchivablePrompts.last {
      model.insert(latestGenerated)
      saveData(in: model)
      // Directly remove the last item assuming saveData was successful
      recentlyGeneratedAndArchivablePrompts.removeLast()
    }
  }
  
  /// After every new image generation, add potential new prompt archivable to the list
  @MainActor
  func addPromptArchivable(currentPrompt: PromptModel, imageUrls: [URL]) {
    var promptTitle = "My Prompt"
    if !currentPrompt.positivePrompt.isEmpty {
      promptTitle = currentPrompt.positivePrompt.prefix(35).appending("…")
    } else if let selectedModel = currentPrompt.selectedModel {
      promptTitle = selectedModel.name
    }
    
    let modelDataMapping = ModelDataMapping()
    let newPromptArchive = modelDataMapping.toArchive(promptModel: currentPrompt)
    
    let newSidebarItem = SidebarItem(title: promptTitle, timestamp: Date(), imageUrls: imageUrls, prompt: newPromptArchive)
    addToRecentlyGeneratedPromptArchivables(newSidebarItem)
  }
  
  func saveData(in model: ModelContext) {
    do {
      try model.save()
    } catch {
      Debug.log("Error saving context: \(error)")
    }
  }
  
  /// DEPRECATED
  func deleteItem(_ item: SidebarItem, in model: ModelContext) {
    model.delete(item)
    // Handle save and error
    do {
      try model.save()
    } catch {
      Debug.log("Error saving context after deletion: \(error)")
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
