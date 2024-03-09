//
//  PastableService.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/7/24.
//

import Foundation
import AppKit

extension Constants.Parsing {
  static let civitaiTags = ["Negative prompt:", "Steps:", "Seed:", "Sampler:", "CFG scale:", "Clip skip:", "Model:", "Model hash:", "VAE:"]
}

class PastableService: ObservableObject {
  static let shared = PastableService()
  
  @Published var canPasteData: Bool = false
  @Published var pastablePromptData: StoredPromptModel? = nil
  
  func newWorkspaceItemFromParsedPasteboard(sidebarModel: SidebarModel?, checkpoints: [CheckpointModel], vaeModels: [VaeModel]) {
    guard let sidebarModel = sidebarModel else {
      Debug.log("[PastableService] newWorkspaceItemFromPasteboard")
      return
    }
    
    if let pastablePromptData = parsePasteboard(checkpoints: checkpoints, vaeModels: vaeModels) {
      sidebarModel.createNewWorkspaceItem(withPrompt: pastablePromptData)
    }
    clearPasteboard()
    canPasteData = false
  }
  
  func parsePasteboard(checkpoints: [CheckpointModel], vaeModels: [VaeModel]) -> StoredPromptModel? {
    guard let pasteboardContent = getPasteboardString() else { return nil }
    
    if canPasteData {
      let parseCivitai = ParseCivitai(checkpoints: checkpoints, vaeModels: vaeModels)
      let storedPromptModel = parseCivitai.parsePastablePromptModel(pasteboardContent)
      return storedPromptModel
    }
    return nil
  }
  
  
  private init() {}
  
  /// Checks the pasteboard asynchronously for pastable data
  func checkForPastableData() async {
    guard let pasteboardContent = getPasteboardString() else { return }
    let dataFound = await didFindGenerationDataTags(from: pasteboardContent)
    await updateCanPasteData(dataFound)
  }
  
  /// Updates the `canPasteData` property on the main actor to ensure it's on the main thread.
  @MainActor
  func updateCanPasteData(_ newValue: Bool) {
    canPasteData = newValue
  }
  
  func clearPasteboard() {
    NSPasteboard.general.clearContents()
  }
  
  /// Returns the string currently stored in the system's pasteboard, if available.
  func getPasteboardString() -> String? {
    NSPasteboard.general.string(forType: .string)
  }
  
  /// Asynchronously determines if the pasteboard content contains generation data by looking for specific keywords.
  func didFindGenerationDataTags(from pasteboardContent: String) async -> Bool {
    await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
      let keywords = Constants.Parsing.civitaiTags
      
      for keyword in keywords {
        group.addTask {
          pasteboardContent.contains(keyword)
        }
      }
      
      var foundKeywords = 0
      for await containsKeyword in group {
        if containsKeyword {
          foundKeywords += 1
          if foundKeywords >= 2 {
            return true
          }
        }
      }
      
      return false
    }
  }
  
  
}
