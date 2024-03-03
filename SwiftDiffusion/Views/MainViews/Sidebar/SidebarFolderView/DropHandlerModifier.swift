//
//  DropHandlerModifier.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/29/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropHandlerModifier: ViewModifier {
  var isHovering: Binding<Bool>?
  var folderId: UUID
  var sidebarModel: SidebarModel
  
  func body(content: Content) -> some View {
    content
      .onDrop(of: [UTType.plainText], isTargeted: isHovering) { providers in
        Debug.log("[DD] Attempting to drop on folder with ID: \(folderId)")
        return providers.first?.loadObject(ofClass: NSString.self) { (nsItem, error) in
          guard let itemIDStr = nsItem as? String, let droppedId = UUID(uuidString: itemIDStr) else {
            Debug.log("[DD] Failed to load the dropped item ID string")
            return
          }
          DispatchQueue.main.async {
            // Ensure folders array is unwrapped safely; use an empty array as a fallback
            let folders = sidebarModel.rootFolder?.folders ?? []
            // Determine if the dropped UUID corresponds to a SidebarItem
            if let _ = sidebarModel.findSidebarItemById(droppedId, in: folders) {
              Debug.log("[DD] Identified item with ID: \(droppedId) for dropping into folder ID: \(folderId)")
              //sidebarModel.moveItem(droppedId, toFolderWithId: folderId)
              sidebarModel.moveSidebarItem(withId: droppedId, toFolderWithId: folderId)
            }
            // Assuming findSidebarFolderById is implemented and handles optionality internally
            else if let _ = sidebarModel.findSidebarFolderById(droppedId, in: folders) {
              Debug.log("[DD] Identified folder with ID: \(droppedId) for dropping into folder ID: \(folderId)")
              sidebarModel.moveSidebarFolder(withId: droppedId, toFolderWithId: folderId)
            } else {
              Debug.log("[Sidebar] The dropped ID does not correspond to a known SidebarItem or SidebarFolder")
            }
            DragState.shared.isDragging = false
          }
        } != nil
      }
  }
}

extension View {
  func onDropHandling(isHovering: Binding<Bool>? = nil, folderId: UUID, sidebarModel: SidebarModel) -> some View {
    modifier(DropHandlerModifier(isHovering: isHovering, folderId: folderId, sidebarModel: sidebarModel))
  }
}

extension SidebarModel {
  func findSidebarFolderById(_ id: UUID?, in folders: [SidebarFolder]) -> SidebarFolder? {
    Debug.log("[Sidebar] findSidebarFolder - Searching for ID: \(String(describing: id))")
    guard let id = id else { return nil }
    for folder in folders {
      if folder.id == id {
        Debug.log("[Sidebar] Folder matched ID: \(folder.name)")
        return folder
      }
      Debug.log("[Sidebar] Recursing into folder: \(folder.name)")
      if let foundFolder = findSidebarFolderById(id, in: folder.folders) {
        return foundFolder
      }
    }
    return nil
  }
}
