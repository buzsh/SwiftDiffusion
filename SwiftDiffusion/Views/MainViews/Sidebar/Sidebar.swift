//
//  Sidebar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData

class SidebarModel: ObservableObject {
  @Published var rootFolder: SidebarFolder? = nil
  @Published var workspaceFolder: SidebarFolder? = nil
  @Published var selectedItemID: UUID? = nil
  @Published var selectedSidebarItem: SidebarItem? = nil
  @Published var currentFolder: SidebarFolder? = nil
  
  func setCurrentFolder(to folder: SidebarFolder?) {
    Debug.log("[DD] ---")
    Debug.log("[DD] setCurrentFolder to: \(String(describing: folder?.name)) \(String(describing: folder?.id))")
    self.currentFolder = folder
    Debug.log("[DD]  self.currentFolder = \(String(describing: folder?.name)) \(String(describing: folder?.id))")
    Debug.log("[DD] ---")
  }
  
  func setSelectedSidebarItem(to sidebarItem: SidebarItem?) {
    self.selectedSidebarItem = sidebarItem
  }
}

struct Sidebar: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarModel: SidebarModel
  @Query private var sidebarFolders: [SidebarFolder]
  
  @Binding var selectedImage: NSImage?
  @Binding var lastSavedImageUrls: [URL]
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        List(selection: $sidebarModel.selectedItemID) {
          WorkspaceFolderView()
          SidebarFolderView()
        }
        .listStyle(SidebarListStyle())
      }
    }
    .onAppear {
      ensureNecessaryFoldersExist()
      sidebarModel.currentFolder = sidebarModel.rootFolder
    }
    .onChange(of: sidebarModel.selectedItemID) { currentItemID, newItemID in
      selectedSidebarItemChanged(from: currentItemID, to: newItemID)
    }
  }
  
  
  
  @Query(filter: #Predicate<SidebarFolder> { folder in
    folder.isRoot == true
  }) private var queryRootFolders: [SidebarFolder]
  
  @Query(filter: #Predicate<SidebarFolder> { folder in
    folder.isWorkspace == true
  }) private var queryWorkspaceFolders: [SidebarFolder]
  
  
  private func ensureNecessaryFoldersExist() {
    sidebarModel.ensureRootFolderExists(for: queryRootFolders, in: modelContext)
    sidebarModel.ensureWorkspaceFolderExists(for: queryWorkspaceFolders, in: modelContext)
  }
  
  
  private func selectedSidebarItemChanged(from currentItemID: UUID?, to newItemID: UUID?) {
    Debug.log("[SidebarView] selectedSidebarItemChanged\n  from: \(String(describing: currentItemID))\n    to: \(String(describing: newItemID))")
    
    let newSelectedItem = sidebarModel.findSidebarItem(by: newItemID, in: sidebarFolders)
    
    if let newSelectedItem = newSelectedItem {
      sidebarModel.setSelectedSidebarItem(to: newSelectedItem)//sidebarModel.selectedSidebarItem = newSelectedItem
      updatePromptAndSelectedImage(newPrompt: currentPrompt, imageUrls: newSelectedItem.imageUrls)
      sidebarModel.setCurrentFolder(to: findFolderForItem(newItemID))
    } else {
      if let newSelectedFolder = findSidebarFolder(by: newItemID, in: sidebarFolders) {
        sidebarModel.setCurrentFolder(to: newSelectedFolder)//sidebarModel.currentFolder = newSelectedFolder
        sidebarModel.setSelectedSidebarItem(to: nil) //sidebarModel.selectedSidebarItem = nil
      }
    }
  }
  
  func updatePromptAndSelectedImage(newPrompt: PromptModel, imageUrls: [URL]) {
    currentPrompt.updateProperties(from: newPrompt)
    if let lastImageUrl = imageUrls.last, let image = NSImage(contentsOf: lastImageUrl) {
      selectedImage = image
    } else {
      selectedImage = nil
    }
  }
}




extension Sidebar {
  
  // Utility function to find a SidebarFolder by ID
  private func findSidebarFolder(by id: UUID?, in folders: [SidebarFolder]) -> SidebarFolder? {
    guard let id = id else { return nil }
    for folder in folders {
      if folder.id == id {
        return folder
      }
      if let foundFolder = findSidebarFolder(by: id, in: folder.folders) {
        return foundFolder
      }
    }
    return nil
  }
  
  // Utility function to find the parent folder for an item
  private func findFolderForItem(_ itemId: UUID?) -> SidebarFolder? {
    guard let itemId = itemId else { return nil }
    for folder in sidebarFolders {
      if folder.items.contains(where: { $0.id == itemId }) {
        return folder
      }
      if let foundFolder = findFolderForItemRecursive(itemId, in: folder.folders) {
        return foundFolder
      }
    }
    return nil
  }
  
  // Recursive helper function to find the parent folder for an item in nested folders
  private func findFolderForItemRecursive(_ itemId: UUID, in folders: [SidebarFolder]) -> SidebarFolder? {
    for folder in folders {
      if folder.items.contains(where: { $0.id == itemId }) {
        return folder
      }
      if let foundFolder = findFolderForItemRecursive(itemId, in: folder.folders) {
        return foundFolder
      }
    }
    return nil
  }
  
}
