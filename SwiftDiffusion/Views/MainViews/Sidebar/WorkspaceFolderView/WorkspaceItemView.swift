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
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  @EnvironmentObject var scriptManager: ScriptManager
  @State private var animatedWidth: CGFloat = 0.0
  
  let sidebarItem: SidebarItem
  
  var progressBarColor: Color {
    switch colorScheme {
    case .light:
      return Color(0x2984F2).opacity(0.5)
    default:
      return Color(0x1C5EC8).opacity(0.6)
    }
  }
  
  var body: some View {
    
    HStack {
      if sidebarItem.title.isEmpty {
        formattedTitleView("Untitled")
          .padding(.leading, 4)
      } else {
        formattedTitleView(sidebarItem.title)
          .padding(.leading, 4)
      }
      Spacer()
    }
    .frame(height: 28)
    .padding(.leading, 4)
    .contentShape(Rectangle())
    .cornerRadius(4)
    .background(
      GeometryReader { outerGeometry in
        ZStack(alignment: .leading) {
          if sidebarItem == sidebarModel.currentlyGeneratingSidebarItem {
            RoundedRectangle(cornerRadius: 4)
              .fill(progressBarColor)
              .frame(width: animatedWidth)
              .listRowInsets(EdgeInsets(top: -8, leading: -20, bottom: -8, trailing: -20))
              .onChange(of: scriptManager.genProgress) {
                withAnimation(.linear(duration: 0.5)) {
                  animatedWidth = outerGeometry.size.width * CGFloat(scriptManager.genProgress)
                }
              }
          }
        }
        .listRowInsets(EdgeInsets(top: -8, leading: -20, bottom: -8, trailing: -20))
      }
    )
    .onChange(of: sidebarModel.selectedSidebarItem?.prompt?.positivePrompt) {
      guard let currentPrompt = sidebarModel.selectedSidebarItem?.prompt else { return }
      
      if sidebarItem == sidebarModel.selectedSidebarItem {
        let trimmedPrompt = currentPrompt.positivePrompt.trimmingCharacters(in: .whitespaces)
        sidebarModel.setSelectedWorkspaceItemTitle(trimmedPrompt, in: modelContext)
      }
    }
    .onChange(of: sidebarModel.queueWorkspaceItemForDeletion) {
      if let workspaceItem = sidebarModel.queueWorkspaceItemForDeletion {
        sidebarModel.workspaceFolder?.remove(item: workspaceItem)
        sidebarModel.saveData(in: modelContext)
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

extension Color {
  init(_ hex: UInt, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: alpha
    )
  }
}
