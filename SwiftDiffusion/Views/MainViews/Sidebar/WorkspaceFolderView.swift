//
//  WorkspaceFolderView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData

struct WorkspaceFolderView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  
  var body: some View {
    newPromptButtonView
    
    Section(header: Text("Workspace")) {
      ForEach(sidebarModel.workspaceFolder?.items ?? []) { sidebarItem in
        WorkspaceItemView(sidebarItem: sidebarItem)
          .onTapGesture {
            sidebarModel.setSelectedSidebarItem(to: sidebarItem)
          }
      }
    }
  }
  
  private var newPromptButtonView: some View {
    HStack {
      Spacer()
      Button(action: {
        let newPromptSidebarItem = SidebarItem(title: "", imageUrls: [], isWorkspaceItem: true)
        newPromptSidebarItem.prompt = StoredPromptModel(isWorkspaceItem: true)
        sidebarModel.workspaceFolder?.add(item: newPromptSidebarItem)
        sidebarModel.saveData(in: modelContext)
        sidebarModel.setSelectedSidebarItem(to: newPromptSidebarItem)
      }) {
        Text("New Prompt")
        Image(systemName: "plus")
      }
      .buttonStyle(.accessoryBar)
    }
  }
  
}
