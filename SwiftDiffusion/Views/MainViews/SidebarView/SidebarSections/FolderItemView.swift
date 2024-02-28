//
//  FolderItemView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderItemView: View {
  @Environment(\.modelContext) private var modelContext
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
    .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
      Debug.log("[DD] Attempting to drop on folder: \(folder.id)")
      return providers.first?.loadObject(ofClass: NSString.self) { (nsItem, error) in
        guard let itemIDStr = nsItem as? NSString else {
          Debug.log("Failed to load item as NSString")
          return
        }
        let itemIdStr = String(itemIDStr)
        Debug.log("[DD] Dropped item ID: \(itemIdStr)")
        DispatchQueue.main.async {
          if let itemId = UUID(uuidString: itemIdStr) {
            Debug.log("[DD] Moving item \(itemId) to folder: \(self.folder.id)")
            self.sidebarViewModel.moveItem(itemId, toFolder: self.folder, in: modelContext)
          }
        }
      } != nil
    }
    
  }
}
