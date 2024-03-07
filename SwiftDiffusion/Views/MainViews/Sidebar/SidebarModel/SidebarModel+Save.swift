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
