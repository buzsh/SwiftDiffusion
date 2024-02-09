//
//  FileHierarchy.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

class FileHierarchy: ObservableObject {
  @Published var rootNodes: [FileNode] = []
  @Published var isLoading: Bool = false
  var rootPath: String
  
  init(rootPath: String) {
    self.rootPath = rootPath
    Task { await self.refresh() }
  }
  
  func refresh() async {
    await MainActor.run {
      self.isLoading = true
    }
    let loadedFiles = await FileHierarchy.loadFiles(from: self.rootPath)
    await MainActor.run {
      self.rootNodes = loadedFiles
      self.isLoading = false
    }
  }
  
  static func loadFiles(from directory: String) async -> [FileNode] {
    var nodes: [FileNode] = []
    let fileManager = FileManager.default
    do {
      let items = try fileManager.contentsOfDirectory(atPath: directory)
      for item in items where item != ".DS_Store" {
        let itemPath = (directory as NSString).appendingPathComponent(item)
        var isDir: ObjCBool = false
        let attributes = try fileManager.attributesOfItem(atPath: itemPath)
        let modificationDate = attributes[.modificationDate] as? Date ?? Date()
        fileManager.fileExists(atPath: itemPath, isDirectory: &isDir)
        if isDir.boolValue {
          let children = await loadFiles(from: itemPath)
          nodes.append(FileNode(name: item, fullPath: itemPath, children: children, lastModified: modificationDate))
        } else {
          nodes.append(FileNode(name: item, fullPath: itemPath, children: nil, lastModified: modificationDate))
        }
      }
      // Sort the nodes by lastModified date in descending order
      nodes.sort { $0.lastModified > $1.lastModified }
    } catch {
      await MainActor.run {
        Debug.log("[FileHierarchy] loadFiles(from: \(directory))\n > \(error)")
      }
    }
    return nodes
  }
  
}

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
