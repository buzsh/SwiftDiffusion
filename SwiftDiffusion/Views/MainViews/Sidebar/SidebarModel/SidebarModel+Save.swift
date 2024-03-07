//
//  SidebarModel+Save.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/7/24.
//

import Foundation

extension SidebarModel {
  @MainActor func saveWorkspaceItem(withPrompt prompt: PromptModel) {
    guard let selectedSidebarItem = selectedSidebarItem
    else { return }
    
    let mapModelData = MapModelData()
    selectedSidebarItem.prompt = mapModelData.toStored(promptModel: prompt)
    saveData(in: modelContext)
  }
}

// TODO: Update with newer syntax
extension SidebarModel {
  @MainActor func storeChangesOfSelectedSidebarItem(with prompt: PromptModel) {
    if let selectedSidebarItem = selectedSidebarItem {
      storeChanges(of: selectedSidebarItem, with: prompt)
    }
  }
  
  @MainActor func storeChanges(of sidebarItem: SidebarItem, with prompt: PromptModel) {
    if workspaceFolderContains(sidebarItem: sidebarItem) {
      let mapModelData = MapModelData()
      let updatedPrompt = mapModelData.toStored(promptModel: prompt)
      
      if !selectedSidebarItemTitle(hasEqualTitleTo: updatedPrompt) && !prompt.positivePrompt.isEmpty {
        if let newTitle = updatedPrompt?.positivePrompt {
          selectedSidebarItem?.title = newTitle.truncatingToLength(Constants.Sidebar.titleLength)
        }
      }
      
      selectedSidebarItem?.prompt = updatedPrompt
      saveData(in: modelContext)
    }
  }
}

extension String {
  /// Truncates the string to the specified length and appends an ellipsis if the string was longer than the specified length.
  ///
  /// - Parameter maxLength: The maximum allowed length of the string.
  /// - Returns: A string truncated to `maxLength` characters with an ellipsis appended if the original string exceeded `maxLength`.
  func truncatingToLength(_ maxLength: Int) -> String {
    if self.count > maxLength {
      let index = self.index(self.startIndex, offsetBy: maxLength)
      return String(self[..<index]).appending("…")
    } else {
      return self
    }
  }
}
