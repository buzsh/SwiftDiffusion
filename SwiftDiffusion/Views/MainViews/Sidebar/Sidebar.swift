//
//  Sidebar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct Sidebar: View {
  @Environment(\.modelContext) var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarModel: SidebarModel
  @Query var sidebarFolders: [SidebarFolder]  
  @Binding var selectedImage: NSImage?
  @Binding var lastSavedImageUrls: [URL]

  var body: some View {
    GeometryReader { geometry in
      VStack {
        ZStack(alignment: .bottom) {
          List(selection: $sidebarModel.selectedItemID) {
            WorkspaceFolderView()
            SidebarFolderView()
            VStack{}.frame(height: Constants.Layout.SidebarToolbar.bottomBarHeight)
          }
          .listStyle(SidebarListStyle())
          .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
            DragState.shared.isDragging = false
            return false
          }
          
          DisplayOptionsBar()
        }
      }
      .frame(width: geometry.size.width)
      .onChange(of: geometry.size.width) {
        sidebarModel.currentWidth = geometry.size.width - sidebarModel.widthOffset
      }
    }
    .onAppear {
      onAppearSetup()
    }
    .onChange(of: sidebarModel.currentFolder) { lastFolder, newFolder in
      Debug.log("[SidebarModel] lastFolder: \(String(describing: lastFolder?.name))")
      Debug.log("[SidebarModel]  newFolder: \(String(describing: newFolder?.name))")
    }
    
    .onChange(of: sidebarModel.selectedItemID) { currentItemID, newItemID in
      selectedSidebarItemChanged(from: currentItemID, to: newItemID)
    }
    .onChange(of: sidebarModel.beginMovableSidebarItemQueue) {
      moveItemInItemQueue()
    }
    .onChange(of: sidebarModel.currentFolder) {
      if let currentFolder = sidebarModel.currentFolder {
        preloadImages(for: currentFolder.items)
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        if sidebarModel.sidebarIsVisible {
          ToolbarSymbolButton(title: "New Folder", symbol: .newFolder, action: {
            withAnimation {
              sidebarModel.createNewUntitledFolderItemInCurrentFolder(in: modelContext)
            }
          })
          ToolbarSymbolButton(title: "New Workspace Item", symbol: .newPrompt, action: {
            withAnimation {
              sidebarModel.createNewWorkspaceItem()
            }
          })
        }
      }
    }
  }
  
  private func onAppearSetup() {
    sidebarModel.setCurrentFolder(to: sidebarModel.rootFolder)
    sidebarModel.updateStorableSidebarItemsInWorkspace()
    sidebarModel.cleanUpEmptyWorkspaceItems()
    sidebarModel.createNewWorkspaceItem()
  }
  
  private func selectedSidebarItemChanged(from currentItemID: UUID?, to newItemID: UUID?) {
    guard newItemID != currentItemID else { return }
    
    Debug.log("[Sidebar] selectedSidebarItemChanged\n  from: \(String(describing: currentItemID))\n    to: \(String(describing: newItemID))")
    Debug.log("[Sidebar] selectedSidebarItemChanged - Entry")
    Debug.log("[Sidebar] From ID: \(String(describing: currentItemID)), To ID: \(String(describing: newItemID))")
    
    let currentlySelectedItem = sidebarModel.findSidebarItem(by: currentItemID, in: sidebarFolders)
    let newlySelectedSidebarItem = sidebarModel.findSidebarItem(by: newItemID, in: sidebarFolders)
    
    if let currentlySelectedItem = currentlySelectedItem {
      sidebarModel.storeChanges(of: currentlySelectedItem, with: currentPrompt)
    }
    
    if let newlySelectedSidebarItem = newlySelectedSidebarItem {
      handleNewlySelected(sidebarItem: newlySelectedSidebarItem, withID: newItemID)
      Debug.log("[Sidebar] Newly selected SidebarItem: \(newlySelectedSidebarItem.title)")
    } else if let newlySelectedFolder = findSidebarFolder(by: newItemID, in: sidebarFolders) {
      Debug.log("[Sidebar] Newly selected Folder: \(newlySelectedFolder.name)")
    } else {
      Debug.log("[Sidebar] No newlySelectedFolder")
    }
  }
  
  func handleNewlySelected(sidebarItem: SidebarItem, withID newItemID: UUID?) {
    sidebarModel.setCurrentFolder(to: findFolderForItem(newItemID))
    
    if let storedPromptModel = sidebarItem.prompt {
      let mapModelData = MapModelData()
      let newPrompt = mapModelData.fromStored(storedPromptModel: storedPromptModel)
      updatePromptAndSelectedImage(newPrompt: newPrompt, imageUrls: sidebarItem.imageUrls)
    }
    sidebarModel.selectedSidebarItem = sidebarItem
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

#Preview {
  CommonPreviews.sidebar
    .frame(width: 300, height: 600)
}


extension Sidebar {
  // Utility function to find a SidebarFolder by ID
  func findSidebarFolder(by id: UUID?, in folders: [SidebarFolder]) -> SidebarFolder? {
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
  func findFolderForItem(_ itemId: UUID?) -> SidebarFolder? {
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
