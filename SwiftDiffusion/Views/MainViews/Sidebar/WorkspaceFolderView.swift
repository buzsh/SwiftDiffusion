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
  
  @State private var workspaceItems: [SidebarItem] = []
  
  var body: some View {
    newPromptButtonView
    
    Section(header: Text("Workspace")) {
      ForEach(workspaceItems) { item in
        SidebarWorkspaceItem(item: item, selectedItemID: $sidebarModel.selectedItemID)
      }
    }
    .onChange(of: sidebarModel.workspaceFolder?.items) {
      workspaceItems = sidebarModel.workspaceFolder?.items ?? []
    }
  }
  
  private var newPromptButtonView: some View {
    HStack {
      Spacer()
      Button(action: {
        let newPromptItem = SidebarItem(title: "New Prompt", imageUrls: [], isWorkspaceItem: true)
        sidebarModel.workspaceFolder?.add(item: newPromptItem)
        sidebarModel.saveData(in: modelContext)
      }) {
        Text("New Prompt")
        Image(systemName: "plus")
      }
      .buttonStyle(.accessoryBar)
    }
  }
  
}
