//
//  SidebarItemSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI

struct SidebarItemSection: View {
  let title: String
  let items: [SidebarItem]
  let folders: [SidebarFolder]
  
  @Binding var selectedItemID: UUID?
  
  var body: some View {
    Section(header: Text("Folders")) {
      ForEach(folders, id: \.self) { folder in
        FolderItemView(folder: folder)
      }
    }
    Section(header: Text(title)) {
      ForEach(items) { item in
        SidebarStoredItemView(item: item)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
          selectedItemID = item.id
        }
      }
    }
  }
}
