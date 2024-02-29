//
//  WorkspaceItemView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData

struct WorkspaceItemView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarModel: SidebarModel
  
  let sidebarItem: SidebarItem
  
  var body: some View {
    HStack {
      if sidebarItem.title.isEmpty {
        formattedTitleView("Untitled")
      } else {
        formattedTitleView(sidebarItem.title)
      }
    }
    
    .onChange(of: currentPrompt.positivePrompt) {
      if sidebarItem.id == sidebarModel.selectedSidebarItem?.id {
        let trimmedPrompt = currentPrompt.positivePrompt.trimmingCharacters(in: .whitespaces)
        sidebarItem.title = trimmedPrompt
      }
    }
    
  }
  
  /// Displays the title for a given sidebar item. Applies specific formatting based on the item's title,
  /// such as italicizing "Untitled" items and adjusting the color to secondary for "Untitled" titles.
  /// This view builder dynamically generates the appropriate view for display.
  /// - Parameter title: The title string of the sidebar item.
  @ViewBuilder private func formattedTitleView(_ title: String) -> some View {
    Text(title)
      .foregroundColor(title == "Untitled" ? .secondary : .primary)
  }
}

extension SidebarModel {
  func setSelectedWorkspaceItemTitle(_ title: String, in model: ModelContext) {
    //shouldCheckForNewSidebarItemToCreate = true
    if workspaceFolderContainsSelectedSidebarItem() {
      selectedSidebarItem?.title = title.count > Constants.Sidebar.titleLength ? String(title.prefix(Constants.Sidebar.titleLength)).appending("…") : title
    }
    saveData(in: model)
  }
  func selectedSidebarItemTitle(hasEqualTitleTo storedPromptModel: StoredPromptModel?) -> Bool {
    if let promptTitle = storedPromptModel?.positivePrompt, let sidebarItemTitle = selectedSidebarItem?.title {
      return promptTitle.prefix(Constants.Sidebar.titleLength) == sidebarItemTitle.prefix(Constants.Sidebar.titleLength)
    }
    return false
  }
}
