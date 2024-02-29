//
//  SidebarFolderItem.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct SidebarFolderItem: View {
  let folder: SidebarFolder
  
  var body: some View {
    HStack {
      Image(systemName: "folder")
        .foregroundStyle(.blue)
        .frame(width: 26)
      Text(folder.name)
      Spacer()
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
    }
    .contentShape(Rectangle())
  }
}
