//
//  WorkspaceFolderView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData

extension SidebarModel {
  var sortedWorkspaceFolderItems: [SidebarItem] {
    workspaceFolder.items.sorted(by: { $0.timestamp < $1.timestamp })
  }
}

struct WorkspaceFolderView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  @State var showWorkspaceItemsPlaceholderButton: Bool = false
  
  var body: some View {
    
    Section(header: Text("Workspace")) {
      ForEach(sidebarModel.sortedWorkspaceFolderItems) { sidebarItem in
        WorkspaceItemView(sidebarItem: sidebarItem)
          .onTapGesture {
            sidebarModel.setSelectedSidebarItem(to: sidebarItem)
          }
      }
    }
    
    newWorkspaceItemPlaceholderButton
  }
  
  private var newWorkspaceItemPlaceholderButton: some View {
    HStack {
      Image(systemName: "plus.bubble")
        .frame(width: 20)
      Text("New Workspace Item")
      Spacer()
      
    }
    .foregroundStyle(.secondary)
    .padding(.vertical, 8).padding(.horizontal, 4)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation {
        sidebarModel.createNewWorkspaceItem()
      }
    }
  }
  
}
