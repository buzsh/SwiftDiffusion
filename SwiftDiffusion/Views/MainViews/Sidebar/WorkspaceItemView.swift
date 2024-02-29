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
  var item: SidebarItem
  @Binding var selectedItemID: UUID?
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarModel: SidebarModel
  
  var body: some View {
    HStack {
      if selectedItemID == item.id && item.isWorkspaceItem {
        formattedTitleView(truncatedOrFullTitle)
      } else {
        formattedTitleView(item.title)
      }
      if item.title == "New Prompt" {
        Spacer()
        Image(systemName: "plus.circle")
      }
    }
    .onChange(of: currentPrompt.positivePrompt) {
      updateTitleBasedOnPrompt(currentPrompt.positivePrompt)
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
  
  /// Determines the appropriate title to display for the sidebar item based on the current prompt.
  /// It trims whitespace from the `currentPrompt.positivePrompt`, checks if the title should remain as "New Prompt",
  /// defaults to "Untitled" if the prompt is empty, or truncates the prompt to 45 characters if necessary.
  /// - Returns: The title string after applying the logic for truncation and defaulting to "Untitled" if needed.
  private var truncatedOrFullTitle: String {
    let trimmedTitle = currentPrompt.positivePrompt.trimmingCharacters(in: .whitespaces)
    
    if sidebarModel.selectedSidebarItem?.title == "New Prompt" && trimmedTitle.isEmpty {
      return "New Prompt"
    } else if trimmedTitle.isEmpty {
      return "Untitled"
    }
    
    return trimmedTitle.count <= Constants.Sidebar.titleLength ? trimmedTitle : "\(trimmedTitle.prefix(Constants.Sidebar.titleLength))…"
  }
  
  /// Responds to changes in `currentPrompt.positivePrompt` by updating the title of the selected sidebar item.
  /// If the sidebar item is "New Prompt" and the prompt is not empty, it sets the title to the trimmed prompt.
  /// If the prompt is empty, it sets the title to "Untitled". This method ensures the sidebar item title
  /// accurately reflects the current state of `currentPrompt.positivePrompt`.
  /// - Parameter prompt: The current prompt string to evaluate and potentially use for updating the sidebar item title.
  private func updateTitleBasedOnPrompt(_ prompt: String) {
    let trimmedPrompt = prompt.trimmingCharacters(in: .whitespaces)
    if sidebarModel.selectedSidebarItem?.title == "New Prompt" {
      if !trimmedPrompt.isEmpty {
        sidebarModel.setSelectedSidebarItemTitle(trimmedPrompt, in: modelContext)
      }
    } else if trimmedPrompt.isEmpty {
      sidebarModel.setSelectedSidebarItemTitle("Untitled", in: modelContext)
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
  
}
