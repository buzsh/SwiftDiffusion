//
//  DebugSelectedSidebarItem.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI

struct DebugSelectedSidebarItem: View {
  @ObservedObject var scriptManager = ScriptManager.shared
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  
  @State private var isExpanded: Bool = false
  
  //@State private var folderPath: String = sidebarViewModel.folderPath.
  
  @State private var selectedFolderTitle: String = "nil"
  
  @State private var selectedSidebarItemTitle: String = "nil"
  
  var body: some View {
    VStack {
      ExpandableSectionHeader(title: "Debug SidebarViewModel", isExpanded: $isExpanded)
      
      if isExpanded {
        VStack(alignment: .leading, spacing: 0) {
          
          VStack {
            Text("selectedFolder: \(selectedFolderTitle)")
              .onChange(of: sidebarViewModel.selectedFolder) {
                selectedFolderTitle = sidebarViewModel.selectedFolder?.name ?? "nil"
              }
            Text("Sidebar Item: \(selectedSidebarItemTitle)")
              .onChange(of: sidebarViewModel.selectedSidebarItem) {
                selectedSidebarItemTitle = sidebarViewModel.selectedSidebarItem?.title ?? "nil"
              }
          }
          .padding(.top, 4)
          .font(.system(size: 12, weight: .regular, design: .monospaced))
          .background(Color.black)
          .foregroundColor(.white)
        }
      }
      
    }
    .padding(.vertical, 10)
  }
  
}

