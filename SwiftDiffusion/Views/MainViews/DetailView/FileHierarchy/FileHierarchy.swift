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
      
      nodes.sort { $0.lastModified > $1.lastModified }
    } catch {
      await MainActor.run {
        Debug.log("[FileHierarchy] loadFiles(from: \(directory))\n > \(error)")
      }
    }
    return nodes
  }
  
}

extension FileHierarchy {
  func findMostRecentlyModifiedImageFile() async -> FileNode? {
    func isImageFile(_ path: String) -> Bool {
      let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff"]
      return imageExtensions.contains((path as NSString).pathExtension.lowercased())
    }
    
    func searchDirectory(_ directory: String) async -> FileNode? {
      var mostRecentImageNode: FileNode? = nil
      let fileManager = FileManager.default
      do {
        let items = try fileManager.contentsOfDirectory(atPath: directory)
        for item in items {
          let itemPath = (directory as NSString).appendingPathComponent(item)
          var isDir: ObjCBool = false
          fileManager.fileExists(atPath: itemPath, isDirectory: &isDir)
          if isDir.boolValue {
            if let foundNode = await searchDirectory(itemPath) {
              if mostRecentImageNode == nil || foundNode.lastModified > mostRecentImageNode!.lastModified {
                mostRecentImageNode = foundNode
              }
            }
          } else if isImageFile(itemPath) {
            let attributes = try fileManager.attributesOfItem(atPath: itemPath)
            if let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date {
              let fileNode = FileNode(name: item, fullPath: itemPath, lastModified: modificationDate)
              if mostRecentImageNode == nil || fileNode.lastModified > mostRecentImageNode!.lastModified {
                mostRecentImageNode = fileNode
              }
            }
          }
        }
      } catch {
        Debug.log("Failed to list directory: \(error.localizedDescription)")
      }
      return mostRecentImageNode
    }
    
    return await searchDirectory(self.rootPath)
  }
}
