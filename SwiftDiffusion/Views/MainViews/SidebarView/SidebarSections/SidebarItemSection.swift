//
//  SidebarItemSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct SidebarItemSection: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  let title: String
  let items: [SidebarItem]
  let folders: [SidebarFolder]
  @Binding var selectedItemID: UUID?
  
  var body: some View {
    Section(header: Text("Folders")) {
      if sidebarViewModel.currentFolder != nil {
        HStack {
          Image(systemName: "chevron.left")
          Text("Back")
          Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
          sidebarViewModel.navigateBack()
        }
        .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
          providers.first?.loadObject(ofClass: NSString.self) { (nsItem, error) in
            guard let itemIDStr = nsItem as? NSString else { return }
            let itemIdStr = String(itemIDStr)
            DispatchQueue.main.async {
              if let itemId = UUID(uuidString: itemIdStr) {
                self.sidebarViewModel.moveItemUp(itemId, in: modelContext)
              }
            }
          }
          return true
        }
        
        Divider()
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
          .onDrag {
            return NSItemProvider(object: String(item.id.uuidString) as NSString)
          }
      }
    }
  }
}
