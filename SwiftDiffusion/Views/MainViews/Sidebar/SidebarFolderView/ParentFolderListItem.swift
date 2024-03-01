//
//  ParentFolderListItem.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/29/24.
//

import SwiftUI

struct ParentFolderListItem: View {
  @EnvironmentObject var sidebarModel: SidebarModel
  var parentFolder: SidebarFolder
  @State private var isHovering = false
  
  var body: some View {
    HStack {
      Image(systemName: "arrow.turn.left.up")
        .foregroundStyle(isHovering ? .white : .secondary)
        .frame(width: 20)
      Text(parentFolder.name)
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
    .onDropHandling(isHovering: $isHovering, folderId: parentFolder.id, sidebarModel: sidebarModel)
  }
}
