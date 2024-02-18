//
//  FileNode.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/11/24.
//

import Foundation

struct FileNode: Identifiable {
  let id: UUID = UUID()
  let name: String
  let fullPath: String
  var children: [FileNode]? = nil
  let lastModified: Date
  
  var isLeaf: Bool {
    return children == nil
  }
}


extension FileNode: Equatable {
  static func == (lhs: FileNode, rhs: FileNode) -> Bool {
    return lhs.id == rhs.id
  }
}

extension FileNode {
  var isImage: Bool {
    let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff"]
    return imageExtensions.contains((fullPath as NSString).pathExtension.lowercased())
  }
  
  var iconName: String {
    isLeaf ? (isImage ? "" : "doc") : "folder"
  }
}
