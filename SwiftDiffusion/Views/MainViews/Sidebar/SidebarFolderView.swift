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
        ParentFolderListItem(parentFolder: parentFolder)
          .onTapGesture {
            sidebarModel.setCurrentFolder(to: parentFolder)
          }
          .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
            Debug.log("[DD] Attempting to drop on folder with ID: \(parentFolder.id)")
            return providers.first?.loadObject(ofClass: NSString.self) { (nsItem, error) in
              guard let itemIDStr = nsItem as? String else {
                Debug.log("[DD] Failed to load the dropped item ID string")
                return
              }
              DispatchQueue.main.async {
                if let itemId = UUID(uuidString: itemIDStr) {
                  Debug.log("[DD] Successfully identified item with ID: \(itemId) for dropping into folder ID: \(parentFolder.id)")
                  sidebarModel.moveSidebarItem(withId: itemId, toFolderWithId: parentFolder.id)
                  DragState.shared.isDragging = false
                }
              }
            } != nil
          }
      }
      
      ForEach(sidebarModel.sortedFoldersAlphabetically) { folder in
        VStack(spacing: 0) {
          SidebarFolderItem(folder: folder)
            .onTapGesture {
              sidebarModel.setCurrentFolder(to: folder)
            }
        }
        .listRowInsets(EdgeInsets())
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
            DragState.shared.isDragging = true
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
  
}


struct ParentFolderListItem: View {
  @EnvironmentObject var sidebarModel: SidebarModel
  var parentFolder: SidebarFolder
  @State private var isHovering = false
  
  var body: some View {
    HStack {
      Image(systemName: "arrow.turn.left.up")
        .foregroundStyle(isHovering ? .white : .secondary)
        .frame(width: 26)
      Text(parentFolder.name)
        .foregroundColor(isHovering ? .white : .primary)
      Spacer()
    }
    .padding(.vertical, 8).padding(.horizontal, 4)
    .contentShape(Rectangle())
    .onHover { hovering in
      if DragState.shared.isDragging {
        isHovering = hovering
      }
    }
    .cornerRadius(8)
    .background(Group {
      if isHovering {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.blue.opacity(0.9))
      }
    })
    .onDropHandling(isHovering: $isHovering, folderId: parentFolder.id, sidebarModel: sidebarModel)
  }
}
