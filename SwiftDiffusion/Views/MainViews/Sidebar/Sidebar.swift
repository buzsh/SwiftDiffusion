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
  
  @Published var currentlyGeneratingSidebarItem: SidebarItem? = nil
  
  
  /// SidebarItems that have been generated and can now be stored to the user's library.
  @Published var storableSidebarItems: [SidebarItem] = []
  
  func addToStorableSidebarItems(sidebarItem: SidebarItem, withImageUrls imageUrls: [URL]) {
    sidebarItem.imageUrls = imageUrls
    storableSidebarItems.append(sidebarItem)
  }
  
  func moveStorableSidebarItemToFolder(sidebarItem: SidebarItem, in modelContext: ModelContext) {
    storableSidebarItems.removeAll(where: { $0 == sidebarItem })
    workspaceFolder?.remove(item: sidebarItem)
    currentFolder?.add(item: sidebarItem)
    saveData(in: modelContext)
  }
  
  func removeSelectedWorkspaceItem() {
    if let workspaceFolder = workspaceFolder, let selectedSidebarItem = selectedSidebarItem {
      if workspaceFolder.items.contains(where: { $0.id == selectedSidebarItem.id }) {
        workspaceFolder.remove(item: selectedSidebarItem)
      }
    }
  }
  
  func selectedItemIsWorkspaceItem() -> Bool {
    if let workspaceFolder = workspaceFolder, workspaceFolder.items.contains(where: { $0 == selectedSidebarItem }) {
      return true
    }
    return false
  }
  
  func selectedItemIsStorableItem() -> Bool {
    if let selectedSidebarItem = selectedSidebarItem, storableSidebarItems.contains(where: { $0 == selectedSidebarItem }) {
      return true
    }
    return false
  }
  
  func setCurrentFolder(to folder: SidebarFolder?) {
    if folder != workspaceFolder {
      self.currentFolder = folder
    }
  }
  
  func setSelectedSidebarItem(to sidebarItem: SidebarItem?) {
    self.selectedSidebarItem = sidebarItem
  }
  
  /*
  func prepareGeneratedSidebarItemForSaving(sidebarItem: SidebarItem, imageUrls: [URL]) {
    sidebarItem.imageUrls = imageUrls
    addSelectedSidebarItemToStorableSidebarItems()
  }
   */
  /// Iterates through workspace items and populates savableSidebarItems with prompts that have previously generated media URLs associated with them.
  func updateStorableSidebarItemsInWorkspace() {
    if let workspaceItems = workspaceFolder?.items {
      for sidebarItem in workspaceItems {
        if sidebarItem.imageUrls.isEmpty == false {
          storableSidebarItems.append(sidebarItem)
        }
      }
    }
    
    
    
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
      sidebarModel.setCurrentFolder(to: sidebarModel.rootFolder)
      sidebarModel.updateStorableSidebarItemsInWorkspace()
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
    Debug.log("updatePromptAndSelectedImage")
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
