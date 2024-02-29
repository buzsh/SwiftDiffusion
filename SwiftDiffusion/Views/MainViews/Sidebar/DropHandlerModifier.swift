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
        DragState.shared.isDragging = false
        return providers.first?.loadObject(ofClass: NSString.self) { (nsItem, error) in
          guard let itemIDStr = nsItem as? String else {
            Debug.log("[DD] Failed to load the dropped item ID string")
            return
          }
          DispatchQueue.main.async {
            if let itemId = UUID(uuidString: itemIDStr) {
              Debug.log("[DD] Successfully identified item with ID: \(itemId) for dropping into folder ID: \(folderId)")
              sidebarModel.moveSidebarItem(withId: itemId, toFolderWithId: folderId)
              DragState.shared.isDragging = false
            }
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
