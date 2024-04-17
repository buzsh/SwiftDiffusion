//
//  FileHierarchy+Control.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/11/24.
//

import Foundation

extension FileHierarchy {
  func nextImage(currentPath: String) -> FileNode? {
    // Assuming a method getAllImageFiles() returns sorted image files by modification date
    let files = getAllImageFiles()
    guard let currentIndex = files.firstIndex(where: { $0.fullPath == currentPath }) else { return nil }
    return currentIndex + 1 < files.count ? files[currentIndex + 1] : nil
  }
  
  func previousImage(currentPath: String) -> FileNode? {
    let files = getAllImageFiles()
    guard let currentIndex = files.firstIndex(where: { $0.fullPath == currentPath }) else { return nil }
    return currentIndex - 1 >= 0 ? files[currentIndex - 1] : nil
  }
}

extension FileHierarchy {
  private func flattenImageNodes(node: FileNode) -> [FileNode] {
    var nodes = [FileNode]()
    if let children = node.children {
      for child in children {
        nodes += flattenImageNodes(node: child)
      }
    } else if node.isImage {
      nodes.append(node)
    }
    return nodes
  }
  
  func getAllImageFiles() -> [FileNode] {
    var allImageNodes = [FileNode]()
    for rootNode in rootNodes {
      allImageNodes += flattenImageNodes(node: rootNode)
    }
    return allImageNodes.sorted(by: { $0.lastModified > $1.lastModified })
  }
}
