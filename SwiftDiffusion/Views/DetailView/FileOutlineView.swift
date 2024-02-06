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
  
  var body: some View {
    VStack(spacing: 0) {
      
      HStack {
        Button(action: {
          self.fileHierarchyObject.refresh()
        }) {
          Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(BorderlessButtonStyle())
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
      }
    }
  }
  
  
  private func thumbnailForImage(at path: String) -> NSImage {
    if let image = NSImage(contentsOfFile: path) {
      return image.resizedToMaintainAspectRatio(targetHeight: 20)//image.resized(to: thumbnailSize)
    } else {
      return NSImage(systemSymbolName: "photo.fill", accessibilityDescription: nil) ?? NSImage()
    }
  }
  
  private func selectNode(_ node: FileNode) {
    selectedNode = node // Update the selected node
    guard node.isLeaf else { return }
    if let image = NSImage(contentsOfFile: node.fullPath) {
      self.selectedImage = image
    }
  }
}

extension NSImage {
  func resized(to newSize: NSSize) -> NSImage {
    let img = NSImage(size: newSize)
    img.lockFocus()
    self.draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: NSRect(x: 0, y: 0, width: self.size.width, height: self.size.height), operation: .copy, fraction: 1.0)
    img.unlockFocus()
    return img
  }
}

extension NSImage {
  func resizedToMaintainAspectRatio(targetHeight: CGFloat) -> NSImage {
    let imageSize = self.size
    let heightRatio = targetHeight / imageSize.height
    let newSize = NSSize(width: imageSize.width * heightRatio, height: targetHeight)
    
    let img = NSImage(size: newSize)
    img.lockFocus()
    self.draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: NSRect.zero, operation: .copy, fraction: 1.0)
    img.unlockFocus()
    return img
  }
}
