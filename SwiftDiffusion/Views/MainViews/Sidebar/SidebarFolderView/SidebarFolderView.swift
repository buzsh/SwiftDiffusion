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
    if let currentFolder = sidebarModel.currentFolder,
       !currentFolder.isRoot || currentFolder.name.isEmpty {
      FolderTitleControl(folder: sidebarModel.currentFolder)
        .onChange(of: currentFolder.name) {
          if currentFolder.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentFolder.name = "Untitled Folder"
            sidebarModel.saveData(in: modelContext)
          }
        }
    }
    
    Section(header: Text("Folders")) {
      if let parentFolder = sidebarModel.currentFolder?.parent {
        ParentFolderListItem(parentFolder: parentFolder)
          .onTapGesture {
            withAnimation {
              sidebarModel.setCurrentFolder(to: parentFolder)
            }
          }
      }
      
      ForEach(sidebarModel.sortedFoldersAlphabetically) { folder in
        VStack(spacing: 0) {
          SidebarFolderItem(folder: folder)
            .onTapGesture {
              withAnimation {
                sidebarModel.setCurrentFolder(to: folder)
              }
            }
        }
      }
      newFolderButtonItem
    }
    
    Section(header: Text(sidebarModel.currentFolder?.name ?? "Files")) {
      ForEach(sidebarModel.sortedCurrentFolderItems) { sidebarItem in
        SidebarStoredItemView(item: sidebarItem)
          .padding(.vertical, 4)
          .contentShape(Rectangle())
          .listRowInsets(EdgeInsets(top: 2, leading: sidebarModel.applyCustomLeadingInsets ? -9 : 0, bottom: 2, trailing: 0))
        
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
    .onChange(of: sidebarModel.currentFolder) { lastFolder, nextFolder in
      if lastFolder == sidebarModel.rootFolder && nextFolder != sidebarModel.rootFolder {
        sidebarModel.applyCustomLeadingInsets = true
      }
    }
  }
  
  private var newFolderButtonItem: some View {
    HStack {
      Image(systemName: "folder.badge.plus")
        .frame(width: 20)
      Text("New Folder")
      Spacer()
      
    }
    .foregroundStyle(.secondary)
    .padding(.vertical, 8).padding(.horizontal, 4)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation {
        sidebarModel.createNewUntitledFolderItemInCurrentFolder(in: modelContext)
      }
    }
  }
  
}

extension SidebarModel {
  
  func createNewUntitledFolderItemInCurrentFolder(in modelContext: ModelContext) {
    var newFolderName = "Untitled Folder"
    let existingFolderNames = currentFolder?.folders.map { $0.name } ?? []
    if existingFolderNames.contains(newFolderName) {
      var suffix = 2
      while existingFolderNames.contains("\(newFolderName) \(suffix)") {
        suffix += 1
      }
      newFolderName = "\(newFolderName) \(suffix)"
    }
    let newFolderItem = SidebarFolder(name: newFolderName)
    currentFolder?.add(folder: newFolderItem)
    saveData(in: modelContext)
  }
  
}
