//
//  SidebarItemSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI

struct SidebarItemSection: View {
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  let title: String
  let items: [SidebarItem]
  let folders: [SidebarFolder]
  @Binding var selectedItemID: UUID?
  
  var body: some View {
    Section(header: Text("Folders")) {
      // Optional "Back" button
      if sidebarViewModel.currentFolder != nil {
        Button(action: {
          sidebarViewModel.navigateBack()
        }) {
          HStack {
            Image(systemName: "chevron.left")
            Text("Back")
          }
        }
      }
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
