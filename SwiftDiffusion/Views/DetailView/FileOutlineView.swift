//
//  FileOutlineView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct FileOutlineView: View {
  @ObservedObject var fileHierarchyObject: FileHierarchy
  @Binding var selectedImage: NSImage?
  @State private var selectedNode: FileNode?
  var onSelectImage: (String) -> Void
  var lastSelectedImagePath: String
  
  var body: some View {
    List(self.fileHierarchyObject.rootNodes, children: \.children) { node in
      HStack {
        if node.isLeaf {
          if node.isImage {
            FileRowView(node: node)
          } else {
            Image(systemName: node.iconName)
            Text(node.name)
          }
        } else {
          Image(systemName: node.iconName)
          Text(node.name)
        }
        Spacer()
      }
      .padding(5)
      .background(self.selectedNode == node ? Color.blue : Color.clear)
      .cornerRadius(5)
      .onTapGesture {
        self.selectNode(node)
      }
      .onAppear {
        if node.fullPath == lastSelectedImagePath {
          self.selectedNode = node
        }
      }
    }
  }
  
  private func isSelected(_ node: FileNode) -> Bool {
    node.fullPath == lastSelectedImagePath
  }
  
  private func thumbnailForImage(at path: String) -> NSImage {
    if let image = NSImage(contentsOfFile: path) {
      return image.resizedToMaintainAspectRatio(targetHeight: 20)
    } else {
      return NSImage(systemSymbolName: "photo.fill", accessibilityDescription: nil) ?? NSImage()
    }
  }
  
  private func selectNode(_ node: FileNode) {
    selectedNode = node
    guard node.isLeaf else { return }
    if let _ = NSImage(contentsOfFile: node.fullPath) {
      self.selectedImage = NSImage(contentsOfFile: node.fullPath)
      Task {
        await MainActor.run {
          onSelectImage(node.fullPath)
        }
      }
    }
  }
  
}
