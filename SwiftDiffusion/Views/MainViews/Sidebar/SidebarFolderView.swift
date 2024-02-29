//
//  SidebarFolderView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

extension SidebarModel {
  var sortedCurrentFolderItems: [SidebarItem] {
    currentFolder?.items.sorted(by: { $0.timestamp > $1.timestamp }) ?? []
  }
}

extension SidebarModel {
  var sortedFoldersAlphabetically: [SidebarFolder] {
    guard let folders = currentFolder?.folders else { return [] }
    return folders.sorted {
      $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
    }
  }
}

struct SidebarFolderView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  
  var body: some View {
    newFolderButtonView
    
    Section(header: Text("Folders")) {
      if let parentFolder = sidebarModel.currentFolder?.parent {
        ListBackButtonItem(parentFolder: parentFolder)
          .onTapGesture {
            sidebarModel.setCurrentFolder(to: parentFolder)
          }
          .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
            let targetFolderId = parentFolder.id // Assuming `self.folder` is the current folder view's context
            Debug.log("[DD] Attempting to drop on folder with ID: \(targetFolderId)")
            return providers.first?.loadObject(ofClass: NSString.self) { (nsItem, error) in
              guard let itemIDStr = nsItem as? String else {
                Debug.log("[DD] Failed to load the dropped item ID string")
                return
              }
              DispatchQueue.main.async {
                if let itemId = UUID(uuidString: itemIDStr) {
                  Debug.log("[DD] Successfully identified item with ID: \(itemId) for dropping into folder ID: \(targetFolderId)")
                  sidebarModel.moveSidebarItem(withId: itemId, toFolderWithId: targetFolderId)
                }
              }
            } != nil
          }
      }
      
      ForEach(sidebarModel.sortedFoldersAlphabetically) { folder in
        SidebarFolderItem(folder: folder)
          .onTapGesture {
            sidebarModel.setCurrentFolder(to: folder)
          }
          .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
            Debug.log("[DD] Attempting to drop on SidebarFolder/SidebarItem")
            return providers.first?.loadObject(ofClass: NSString.self) { (nsItem, error) in
              guard let itemIDStr = nsItem as? String else {
                Debug.log("[DD] Failed to load the dropped item ID string")
                return
              }
              DispatchQueue.main.async {
                if let itemId = UUID(uuidString: itemIDStr) {
                  Debug.log("[DD] Successfully dropped item with ID: \(itemId). Preparing to move the item.")
                  // Assuming you have a method to get the folder name or ID where the item will be moved
                  let targetFolderName = "Target Folder Name" // Example placeholder
                  Debug.log("[DD] Moving item with ID: \(itemId) to \(targetFolderName)")
                  // Perform the move operation
                  sidebarModel.moveSidebarItem(withId: itemId, toFolderWithId: folder.id)
                }
              }
            } != nil
          }
      }
    }
    
    Section(header: Text(sidebarModel.currentFolder?.name ?? "Files")) {
      ForEach(sidebarModel.sortedCurrentFolderItems) { sidebarItem in
        SidebarStoredItemView(item: sidebarItem)
          .padding(.vertical, 2)
          .contentShape(Rectangle())
          .onTapGesture {
            sidebarModel.setSelectedSidebarItem(to: sidebarItem)
          }
          .onDrag {
            Debug.log("[DD] Dragging item with ID: \(sidebarItem.id.uuidString) - Title: \(sidebarItem.title)")
            return NSItemProvider(object: String(sidebarItem.id.uuidString) as NSString)
          }
          
      }
    }
  }
  
  
  private var newFolderButtonView: some View {
    HStack {
      Spacer()
      Button(action: {
        var newFolderName = "Untitled Folder"
        let existingFolderNames = sidebarModel.currentFolder?.folders.map { $0.name } ?? []
        if existingFolderNames.contains(newFolderName) {
          var suffix = 2
          while existingFolderNames.contains("\(newFolderName) \(suffix)") {
            suffix += 1
          }
          newFolderName = "\(newFolderName) \(suffix)"
        }
        
        let newFolderItem = SidebarFolder(name: newFolderName)
        sidebarModel.currentFolder?.add(folder: newFolderItem)
        sidebarModel.saveData(in: modelContext)
      }) {
        Text("New Folder")
        Image(systemName: "folder.badge.plus")
      }
      .buttonStyle(.accessoryBar)
    }
  }
  
  private struct ListBackButtonItem: View {
    var parentFolder: SidebarFolder
    
    var body: some View {
      HStack {
        Image(systemName: "arrow.turn.left.up")
          .foregroundStyle(.secondary)
          .frame(width: 26)
        Text(parentFolder.name)
        Spacer()
      }
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
  }
  
}


extension SidebarFolderView {
  
}
