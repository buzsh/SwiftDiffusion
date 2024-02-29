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
    .padding(.vertical, 8)
    .padding(.horizontal, 8)
    .contentShape(Rectangle())
    .onHover { hovering in
      if DragState.shared.isDragging {
        isHovering = hovering
      }
    }
    .background(isHovering ? AnyView(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.2))) : AnyView(Color.clear))
    .onDrop(of: [UTType.plainText], isTargeted: $isHovering) { providers in
      false
    }
  }
}

#Preview {
  let sidebarFolder = SidebarFolder(name: "Some Sidebar")
  return SidebarFolderItem(folder: sidebarFolder)
}
