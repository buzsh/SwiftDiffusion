//
//  ContentView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI

extension Constants.Layout {
  static let verticalPadding: CGFloat = 8
}

enum ViewManager {
  case main, console
  
  var title: String {
    switch self {
    case .main: return "Home"
    case .console: return "Console"
    }
  }
}

extension ViewManager: Hashable, Identifiable {
  var id: Self { self }
}

struct ContentView: View {
  // Main
  @ObservedObject var mainViewModel: MainViewModel
  // Console
  @ObservedObject var scriptManager: ScriptManager
  @Binding var scriptPathInput: String
  // Views
  @State private var selectedView: ViewManager = .main
  // Detail
  @StateObject private var fileHierarchy = FileHierarchy(rootPath: "/Users/jb/Dev/GitHub/stable-diffusion-webui/outputs")
  @State private var selectedImage: NSImage? = NSImage(named: "DiffusionPlaceholder")
  
  
  var body: some View {
    NavigationSplitView {
      // Sidebar
      List {
        NavigationLink(value: ViewManager.main) {
          Label("Prompt", systemImage: "text.bubble")
        }
        NavigationLink(value: ViewManager.console) {
          Label("Console", systemImage: "terminal")
        }
      }
      .listStyle(SidebarListStyle())
      
    } content: {
      // Detail view for selected item
      switch selectedView {
      case .main:
        MainView(prompt: mainViewModel)
      case .console:
        ConsoleView(scriptManager: scriptManager, scriptPathInput: $scriptPathInput)
      }
    } detail: {
      // Image, FileSelect DetailView
      DetailView(selectedImage: $selectedImage, fileHierarchyObject: fileHierarchy)
    }
    .background(VisualEffectBlurView(material: .headerView, blendingMode: .behindWindow))
    .onAppear {
      scriptPathInput = scriptManager.scriptPath ?? ""
    }
    .navigationTitle(selectedView.title)
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        Picker("Options", selection: $selectedView) {
          Text("Prompt").tag(ViewManager.main)
          Text("Console").tag(ViewManager.console)
        }
        .pickerStyle(SegmentedPickerStyle())
      }
      
      ToolbarItem(placement: .automatic) {
        Button(action: {
          Debug.log("Toolbar item selected")
        }) {
          Image(systemName: "gear")
        }
      }
    }
  }
  
}

/*
 #Preview {
 ContentView()
 }
 */

import SwiftUI

struct DetailView: View {
  @Binding var selectedImage: NSImage?
  var fileHierarchyObject: FileHierarchy
  
  var body: some View {
    VSplitView {
      if let selectedImage = selectedImage {
        Image(nsImage: selectedImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
      } else if NSImage(named: "DiffusionPlaceholder") != nil {
        Image(nsImage: NSImage(named: "DiffusionPlaceholder")!)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
      } else {
        Rectangle()
          .foregroundColor(.gray)
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
      }
      
      FileOutlineView(fileHierarchyObject: fileHierarchyObject, selectedImage: $selectedImage)
        .frame(minWidth: 250, idealWidth: 300, maxWidth: .infinity)
        .frame(minHeight: 140, idealHeight: 200)
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


class FileHierarchy: ObservableObject {
  @Published var rootNodes: [FileNode]
  private var rootPath: String
  
  init(rootPath: String) {
    self.rootPath = rootPath
    self.rootNodes = FileHierarchy.loadFiles(from: rootPath)
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

struct FileRowView: View {
  let node: FileNode
  @StateObject private var thumbnailLoader = ThumbnailLoader()
  
  var body: some View {
    HStack {
      if let thumbnailImage = thumbnailLoader.thumbnailImage {
        Image(nsImage: thumbnailImage)
          .resizable()
          .scaledToFit()
          .frame(width: 20, height: 20)
      } else {
        // Placeholder or loading indicator
        ProgressView()
          .frame(width: 20, height: 20)
      }
      
      Text(node.name)
      
      Spacer()
      
      // Display the dimensions and file size if available
      if let size = thumbnailLoader.imageSize {
        let width = Int(size.width)
        let height = Int(size.height)
        let dimensionString = "\(width)x\(height)"
        let fileSizeString = thumbnailLoader.fileSize
        
        Text("\(fileSizeString)  •  \(dimensionString)")
          .font(.caption)
          .foregroundColor(.gray)
      }
    }
    .onAppear {
      thumbnailLoader.loadThumbnail(for: node)
    }
  }
}



import Foundation
import SwiftUI

class ThumbnailLoader: ObservableObject {
  @Published var thumbnailImage: NSImage?
  @Published var imageSize: CGSize?
  @Published var fileSize: String = ""
  
  func loadThumbnail(for node: FileNode) {
    DispatchQueue.global(qos: .userInitiated).async {
      let fileURL = URL(fileURLWithPath: node.fullPath)
      guard let image = NSImage(contentsOfFile: node.fullPath) else {
        DispatchQueue.main.async {
          self.thumbnailImage = NSImage(systemSymbolName: "photo.fill", accessibilityDescription: nil) ?? NSImage()
        }
        return
      }
      
      let thumbnail = image.resizedToMaintainAspectRatio(targetHeight: 40)
      
      // Fetch and format file size
      let fileSizeAttributes = try? FileManager.default.attributesOfItem(atPath: node.fullPath)
      if let fileSize = fileSizeAttributes?[.size] as? NSNumber {
        DispatchQueue.main.async {
          self.fileSize = self.formatFileSize(fileSize.intValue)
        }
      }
      
      DispatchQueue.main.async {
        self.thumbnailImage = thumbnail
        self.imageSize = image.size // Store the original image size
      }
    }
  }
  
  private func formatFileSize(_ size: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB] // Adjust based on preference
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(size))
  }
}
