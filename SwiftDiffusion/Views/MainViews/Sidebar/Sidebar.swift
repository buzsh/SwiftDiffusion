//
//  Sidebar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData

struct Sidebar: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarModel: SidebarModel
  @Query private var sidebarFolders: [SidebarFolder]
  
  @State var showingDeleteSelectedSidebarItemConfirmationAlert: Bool = false
  
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
      .frame(width: geometry.size.width)
      .onChange(of: geometry.size.width) {
        sidebarModel.currentWidth = geometry.size.width - 32
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
    .onChange(of: sidebarModel.promptUserToConfirmDeletion) {
      showingDeleteSelectedSidebarItemConfirmationAlert = sidebarModel.promptUserToConfirmDeletion
    }
    .alert(isPresented: $showingDeleteSelectedSidebarItemConfirmationAlert) {
      Alert(
        title: Text("Are you sure you want to delete this item?"),
        primaryButton: .destructive(Text("Delete")) {
          sidebarModel.deleteSelectedSidebarItemFromStorage(in: modelContext)
        },
        secondaryButton: .cancel()
      )
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
    Debug.log("[Sidebar] selectedSidebarItemChanged\n  from: \(String(describing: currentItemID))\n    to: \(String(describing: newItemID))")
    
    Debug.log("[Sidebar] selectedSidebarItemChanged - Entry")
    Debug.log("[Sidebar] From ID: \(String(describing: currentItemID)), To ID: \(String(describing: newItemID))")

    
    let currentlySelectedItem = sidebarModel.findSidebarItem(by: currentItemID, in: sidebarFolders)
    let newlySelectedSidebarItem = sidebarModel.findSidebarItem(by: newItemID, in: sidebarFolders)
    
    if let currentlySelectedItem = currentlySelectedItem {
      sidebarModel.storeChanges(of: currentlySelectedItem, with: currentPrompt, in: modelContext)
    }
    
    if let newlySelectedSidebarItem = newlySelectedSidebarItem {
      handleNewlySelected(sidebarItem: newlySelectedSidebarItem, withID: newItemID)
      Debug.log("[Sidebar] Newly selected SidebarItem: \(newlySelectedSidebarItem.title)")
    } else {
      Debug.log("[Sidebar] No newly selected item found, trying to find folder")
    }
    
    if let newlySelectedFolder = findSidebarFolder(by: newItemID, in: sidebarFolders) {
      //sidebarModel.selectedItemID = nil
      
      Debug.log("[Sidebar] Newly selected Folder: \(newlySelectedFolder.name)")
    } else {
      Debug.log("[Sidebar] No newlySelectedFolder")
    }
    
    
  }
  
  func handleNewlySelected(sidebarItem: SidebarItem, withID newItemID: UUID?) {
    sidebarModel.setSelectedSidebarItem(to: sidebarItem)
    sidebarModel.setCurrentFolder(to: findFolderForItem(newItemID))
    
    if let storedPromptModel = sidebarItem.prompt {
      let mapModelData = MapModelData()
      let newPrompt = mapModelData.fromStored(storedPromptModel: storedPromptModel)
      updatePromptAndSelectedImage(newPrompt: newPrompt, imageUrls: sidebarItem.imageUrls)
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
    Debug.log("[Sidebar] findSidebarFolder - Searching for ID: \(String(describing: id))")
    guard let id = id else { return nil }
    for folder in folders {
      if folder.id == id {
        Debug.log("[Sidebar] Folder matched ID: \(folder.name)")
        return folder
      }
      Debug.log("[Sidebar] Recursing into folder: \(folder.name)")
      if let foundFolder = findSidebarFolder(by: id, in: folder.folders) {
        return foundFolder
      }
    }
    return nil
  }
  
  // Utility function to find the parent folder for an item
  private func findFolderForItem(_ itemId: UUID?) -> SidebarFolder? {
    Debug.log("[Sidebar] findFolderForItem - Searching for item ID: \(String(describing: itemId))")
    guard let itemId = itemId else { return nil }
    for folder in sidebarFolders {
      if folder.items.contains(where: { $0.id == itemId }) {
        Debug.log("[Sidebar] Found item in folder: \(folder.name)")
        return folder
      }
      Debug.log("[Sidebar] Recursing into folder: \(folder.name) for item search")
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
