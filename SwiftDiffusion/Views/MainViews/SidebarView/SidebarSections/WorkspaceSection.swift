//
//  WorkspaceSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import SwiftUI

struct WorkspaceSection: View {
  var workspaceItems: [SidebarItem]
  @Binding var selectedItemID: UUID?
  
  var body: some View {
    Section(header: Text("Workspace")) {
      ForEach(workspaceItems) { item in
        SidebarWorkspaceItem(item: item, selectedItemID: $selectedItemID)
      }
    }
  }
  
}
