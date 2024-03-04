//
//  WorkspaceItemView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData

extension Constants.Sidebar {
  static let titleLength: Int = 80
}

struct WorkspaceItemView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarModel: SidebarModel
  @EnvironmentObject var scriptManager: ScriptManager
  
  let sidebarItem: SidebarItem
  
  var body: some View {
    HStack {
      if sidebarItem.title.isEmpty {
        formattedTitleView("Untitled")
      } else {
        formattedTitleView(sidebarItem.title)
      }
      Spacer()
    }
    
    .frame(height: 30)
    .padding(.horizontal, 4)
    .contentShape(Rectangle())
    .cornerRadius(4)
    // if sidebarItem == sidebarModel.currentlyGeneratingSidebarItem  || sidebarItem == sidebarModel.selectedSidebarItem {
    .background(
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          if sidebarItem == sidebarModel.currentlyGeneratingSidebarItem {
            let progressWidth = geometry.size.width * (CGFloat(scriptManager.genProgress))
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.blue.opacity(0.9))
              .frame(width: progressWidth)
          }
        }
      }
    )
    .animation(.linear(duration: 0.5), value: scriptManager.genProgress)
    
    .onChange(of: currentPrompt.positivePrompt) {
      if sidebarItem.id == sidebarModel.selectedSidebarItem?.id {
        let trimmedPrompt = currentPrompt.positivePrompt.trimmingCharacters(in: .whitespaces)
        sidebarModel.setSelectedWorkspaceItemTitle(trimmedPrompt, in: modelContext)
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
      saveData(in: model)
      updateControlBarView = true
    }
  }
  func selectedSidebarItemTitle(hasEqualTitleTo storedPromptModel: StoredPromptModel?) -> Bool {
    if let promptTitle = storedPromptModel?.positivePrompt, let sidebarItemTitle = selectedSidebarItem?.title {
      return promptTitle.prefix(Constants.Sidebar.titleLength) == sidebarItemTitle.prefix(Constants.Sidebar.titleLength)
    }
    return false
  }
}
