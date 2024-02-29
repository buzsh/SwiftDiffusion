//
//  SidebarFolderView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData

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
      }
      
      ForEach(sidebarModel.currentFolder?.folders ?? []) { folder in
        SidebarFolderItem(folder: folder)
          .onTapGesture {
            sidebarModel.setCurrentFolder(to: folder)
          }
      }
    }
    
    Section(header: Text(sidebarModel.currentFolder?.name ?? "Files")) {
      ForEach(sidebarModel.currentFolder?.items ?? []) { item in
        SidebarStoredItemView(item: item)
          .padding(.vertical, 2)
          .contentShape(Rectangle())
          .onTapGesture {
            sidebarModel.setSelectedSidebarItem(to: item)
          }
          .onDrag {
            Debug.log("[DD] Dragging item with ID: \(item.id.uuidString)")
            return NSItemProvider(object: String(item.id.uuidString) as NSString)
          }
      }
    }
  }
  
  
  private var newFolderButtonView: some View {
    HStack {
      Spacer()
      Button(action: {
        let newFolderItem = SidebarFolder(name: "New Folder")
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
        Image(systemName: "arrow.turn.left.up") // "chevron.left"
          .foregroundStyle(.secondary)
          .frame(width: 26)
        Text(parentFolder.name) // Text("Back")
        Spacer()
      }
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
  }
  
}
