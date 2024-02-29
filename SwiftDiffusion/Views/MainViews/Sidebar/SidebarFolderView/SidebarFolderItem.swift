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
        .frame(width: 20)
      Text(folder.name)
        .foregroundColor(isHovering ? .white : .primary)
      Spacer()
    }
    .padding(.vertical, 8).padding(.horizontal, 4)
    .contentShape(Rectangle())
    .onHover { hovering in
      if DragState.shared.isDragging {
        isHovering = hovering
      }
    }
    .cornerRadius(8)
    .background(Group {
      if isHovering {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.blue.opacity(0.9))
      }
    })
    .onDropHandling(isHovering: $isHovering, folderId: folder.id, sidebarModel: sidebarModel)
  }
}

#Preview {
  let sidebarFolder = SidebarFolder(name: "Some Sidebar")
  return SidebarFolderItem(folder: sidebarFolder)
}
