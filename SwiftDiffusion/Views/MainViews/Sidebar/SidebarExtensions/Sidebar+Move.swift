//
//  Sidebar+Move.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/29/24.
//

import SwiftUI
import SwiftData

extension Sidebar {
  func moveItemInItemQueue() {
    if sidebarModel.beginMovableSidebarItemQueue,
        let sidebarId = sidebarModel.queueMovableSidebarItemID,
        let folderId = sidebarModel.queueDestinationFolderID {
      moveItem(sidebarId, toFolderWithId: folderId)
    }
    sidebarModel.queueMovableSidebarItemID = nil
    sidebarModel.queueDestinationFolderID = nil
    sidebarModel.beginMovableSidebarItemQueue = false
  }
}

extension Sidebar {
  func moveItem(_ itemId: UUID, toFolderWithId targetFolderId: UUID) {
    Debug.log("[Sidebar] moveItem - Moving item with ID: \(itemId) to folder with ID: \(targetFolderId)")
    
    guard let sourceFolder = findFolderForItem(itemId),
          let targetFolder = findSidebarFolder(by: targetFolderId, in: sidebarFolders),
          let itemIndex = sourceFolder.items.firstIndex(where: { $0.id == itemId }) else {
      Debug.log("[Sidebar] Error: Unable to find source or target folder for item ID: \(itemId)")
      return
    }
    
    let itemToMove = sourceFolder.items.remove(at: itemIndex)
    targetFolder.items.append(itemToMove)
    Debug.log("[Sidebar] Successfully moved item \(itemToMove.title) to \(targetFolder.name)")
    sidebarModel.saveData(in: modelContext)
    SoundUtility.play(systemSound: .mount)
  }
}

extension Sidebar {
  func moveFolder(_ folderId: UUID, toFolderWithId targetFolderId: UUID) {
    Debug.log("[Sidebar] moveFolder - Moving folder with ID: \(folderId) to folder with ID: \(targetFolderId)")
    
    guard let sourceFolderParent = findParentFolderForFolder(folderId),
          let targetFolder = findSidebarFolder(by: targetFolderId, in: sidebarFolders),
          let folderIndex = sourceFolderParent.folders.firstIndex(where: { $0.id == folderId }) else {
      Debug.log("[Sidebar] Error: Unable to find source parent or target folder for folder ID: \(folderId)")
      return
    }
    
    let folderToMove = sourceFolderParent.folders.remove(at: folderIndex)
    targetFolder.folders.append(folderToMove)
    Debug.log("[Sidebar] Successfully moved folder \(folderToMove.name) to \(targetFolder.name)")
    sidebarModel.saveData(in: modelContext)
    SoundUtility.play(systemSound: .mount)
  }
}

extension Sidebar {
  func moveItemInQueue() {
    if sidebarModel.beginMovableSidebarItemQueue,
       let sidebarId = sidebarModel.queueMovableSidebarItemID,
       let folderId = sidebarModel.queueDestinationFolderID {
      moveItem(sidebarId, toFolderWithId: folderId)
      clearItemMoveQueue()
    }

    if sidebarModel.beginMovableFolderQueue,
       let folderId = sidebarModel.queueMovableFolderID,
       let targetFolderId = sidebarModel.queueDestinationFolderID {
      moveFolder(folderId, toFolderWithId: targetFolderId)
      clearFolderMoveQueue()
    }
  }

  func clearItemMoveQueue() {
    sidebarModel.queueMovableSidebarItemID = nil
    sidebarModel.queueDestinationFolderID = nil
    sidebarModel.beginMovableSidebarItemQueue = false
  }

  func clearFolderMoveQueue() {
    sidebarModel.queueMovableFolderID = nil
    sidebarModel.queueDestinationFolderID = nil
    sidebarModel.beginMovableFolderQueue = false
  }
}
