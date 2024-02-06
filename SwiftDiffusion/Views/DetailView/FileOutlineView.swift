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
    VStack(spacing: 0) {
      
      HStack {
        Button(action: {
          Task {
            await self.fileHierarchyObject.refresh()
          }
        }) {
          Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(BorderlessButtonStyle())
        
        if fileHierarchyObject.isLoading {
          ProgressView()
            .progressViewStyle(.circular)
            .controlSize(.small)
            .padding(.leading, 5)
        }
      }
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 30)
      .background(.bar)
      
      Divider()
        .overlay(Color.black.opacity(0.1))
      
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
