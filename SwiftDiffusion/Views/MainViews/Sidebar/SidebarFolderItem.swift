//
//  SidebarFolderItem.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import UniformTypeIdentifiers

class DragState: ObservableObject {
  static let shared = DragState()
  @Published var isDragging = false
}

struct SidebarFolderItem: View {
  @EnvironmentObject var sidebarModel: SidebarModel
  let folder: SidebarFolder
  @State private var isHovering = false
  
  var body: some View {
    HStack {
      Image(systemName: "folder")
        .foregroundStyle(isHovering ? .white : .blue)
        .frame(width: 26)
      Text(folder.name)
        .foregroundColor(isHovering ? .white : .primary)
      Spacer()
      Image(systemName: "chevron.right")
        .foregroundColor(isHovering ? .white : .secondary)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 4)
    .contentShape(Rectangle())
    .onHover { hovering in
      if DragState.shared.isDragging {
        isHovering = hovering
      }
    }
    //.background(isHovering ? Color.blue.opacity(0.9) : Color.clear)
    .cornerRadius(8)
    .background(Group {
      if isHovering {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.blue.opacity(0.9))
      }
    })
    .onDrop(of: [UTType.plainText], isTargeted: $isHovering) { providers in
      Debug.log("[DD] Attempting to drop on folder with ID: \(folder.id)")
      DragState.shared.isDragging = false
      return providers.first?.loadObject(ofClass: NSString.self) { (nsItem, error) in
        guard let itemIDStr = nsItem as? String else {
          Debug.log("[DD] Failed to load the dropped item ID string")
          return
        }
        DispatchQueue.main.async {
          if let itemId = UUID(uuidString: itemIDStr) {
            Debug.log("[DD] Successfully identified item with ID: \(itemId) for dropping into folder ID: \(folder.id)")
            sidebarModel.moveSidebarItem(withId: itemId, toFolderWithId: folder.id)
            DragState.shared.isDragging = false
          }
        }
      } != nil
    }
  }
}

#Preview {
  let sidebarFolder = SidebarFolder(name: "Some Sidebar")
  return SidebarFolderItem(folder: sidebarFolder)
}
