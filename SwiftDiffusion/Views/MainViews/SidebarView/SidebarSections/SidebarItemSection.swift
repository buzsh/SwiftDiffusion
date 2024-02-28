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
          Debug.log("[DD] Attempting to drop on 'Back' action")
          return providers.first?.loadObject(ofClass: NSString.self) { (nsItem, error) in
            guard let itemIDStr = nsItem as? NSString else {
              Debug.log("Failed to load item as NSString for 'Back' action")
              return
            }
            let itemIdStr = String(itemIDStr)
            Debug.log("[DD] Dropped item ID for 'Back' action: \(itemIdStr)")
            DispatchQueue.main.async {
              if let itemId = UUID(uuidString: itemIdStr) {
                Debug.log("[DD] Moving item \(itemId) up a level")
                self.sidebarViewModel.moveItemUp(itemId, in: modelContext)
              }
            }
          } != nil
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
            Debug.log("[DD] Dragging item with ID: \(item.id.uuidString)")
            return NSItemProvider(object: String(item.id.uuidString) as NSString)
          }
      }
    }
  }
}
