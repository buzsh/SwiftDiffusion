//
//  FileHierarchy.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import Foundation

class FileHierarchy: ObservableObject {
  @Published var rootNodes: [FileNode] = []
  var rootPath: String
  
  init(rootPath: String) {
    self.rootPath = rootPath
    self.refresh() // Call refresh here to initially populate rootNodes
  }
  
  func refresh() {
    self.rootNodes = FileHierarchy.loadFiles(from: self.rootPath)
  }
  
  static func loadFiles(from directory: String) -> [FileNode] {
    let fileManager = FileManager.default
    do {
      let items = try fileManager.contentsOfDirectory(atPath: directory)
      return items.compactMap { item -> FileNode? in
        
        if item == ".DS_Store" { return nil }
        
        let itemPath = (directory as NSString).appendingPathComponent(item)
        var isDir: ObjCBool = false
        fileManager.fileExists(atPath: itemPath, isDirectory: &isDir)
        if isDir.boolValue {
          return FileNode(name: item, fullPath: itemPath, children: loadFiles(from: itemPath))
        } else {
          return FileNode(name: item, fullPath: itemPath, children: nil)
        }
      }
    } catch {
      print(error)
      return []
    }
  }
}

struct FileNode: Identifiable {
  let id: UUID = UUID()
  let name: String
  let fullPath: String
  var children: [FileNode]? = nil
  
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
