//
//  SidebarViewModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/14/24.
//

import SwiftUI
import SwiftData

class SidebarViewModel: ObservableObject {
  
  func saveData(in model: ModelContext) {
    do {
      try model.save()
    } catch {
      Debug.log("Error saving context: \(error)")
    }
  }
  
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
