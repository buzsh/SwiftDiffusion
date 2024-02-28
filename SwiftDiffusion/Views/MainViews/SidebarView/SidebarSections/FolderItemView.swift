//
//  FolderItemView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI

struct FolderItemView: View {
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  let folder: SidebarFolder
  
  var body: some View {
    HStack {
      Image(systemName: "folder")
      Text(folder.name)
      Spacer()
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      sidebarViewModel.navigateToFolder(folder)
    }
  }
}
