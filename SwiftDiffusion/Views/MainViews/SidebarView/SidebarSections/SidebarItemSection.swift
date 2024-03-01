//
//  SidebarItemSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SidebarItemSection: View {
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  @Environment(\.modelContext) private var modelContext
  @Binding var selectedItemID: UUID?
  
  var body: some View {
    List {
      Button(action: {
        // Assuming you want to prompt for a folder name or set a default name
        let folderName = "New Folder" // You might want to make this dynamic
        sidebarViewModel.addFolderToCurrentFolder(name: folderName, in: modelContext)
      }) {
        HStack {
          Image(systemName: "plus.circle.fill")
          Text("Add Folder")
        }
      }
      
      if let currentFolder = sidebarViewModel.currentFolder {
        sectionView(title: currentFolder.name, items: currentFolder.items, folders: currentFolder.folders)
      } else {
        if let rootFolder = sidebarViewModel.rootFolder {
          sectionView(title: rootFolder.name, items: rootFolder.items, folders: rootFolder.folders)
        }
      }
    }
    .frame(maxHeight: .infinity)
    .listStyle(SidebarListStyle())
  }
  
  
  private func sectionView(title: String, items: [SidebarItem], folders: [SidebarFolder]) -> some View {
    Group {
      Section(header: Text("Folders")) {
        backButtonView
        Divider()
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
              self.selectedItemID = item.id
            }
            .onDrag {
              Debug.log("[DD] Dragging item with ID: \(item.id.uuidString)")
              return NSItemProvider(object: String(item.id.uuidString) as NSString)
            }
        }
      }
    }
  }
  
  private var backButtonView: some View {
    Group {
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
      }
    }
  }
}

extension SidebarViewModel {
  func addFolderToCurrentFolder(name: String, in model: ModelContext) {
    let newFolder = SidebarFolder(name: name)
    if let currentFolder = currentFolder {
      currentFolder.folders.append(newFolder)
    } else {
      rootFolder?.folders.append(newFolder)
    }
    try? model.save()
    // You might want to handle any necessary model updates or UI refreshes here
  }
}

  /*
  private func sectionView(title: String, items: [SidebarItem], folders: [SidebarFolder]) -> some View {
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
*/
