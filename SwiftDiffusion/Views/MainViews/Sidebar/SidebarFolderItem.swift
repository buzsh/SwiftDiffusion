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
  let folder: SidebarFolder
  @State private var isHovering = false
  
  var body: some View {
    HStack {
      Image(systemName: "folder")
        .foregroundStyle(.blue)
        .frame(width: 26)
      Text(folder.name)
      Spacer()
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
    }
    .contentShape(Rectangle())
    .onHover { hovering in
      if DragState.shared.isDragging {
        isHovering = hovering
      }
    }
    .background(isHovering ? Color.blue.opacity(0.2) : Color.clear)
    .onDrop(of: [UTType.plainText], isTargeted: $isHovering) { providers in
      false
    }
  }
}
