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
  @StateObject private var fileHierarchy = FileHierarchy(rootPath: "/Users/jb/Dev/GitHub/stable-diffusion-webui/outputs") //"/path/to/your/directory")
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
      VStack {
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
          // fallback dark gray box
          Rectangle()
            .foregroundColor(.gray)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
        }
        
        // OutlineView
        FileOutlineView(fileHierarchy: $fileHierarchy.rootNodes, selectedImage: $selectedImage)
          .frame(minWidth: 250, idealWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
      }
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

struct FileNode: Identifiable {
  let id: UUID = UUID()
  let name: String
  let fullPath: String // Add fullPath to keep track of the item's path
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
    // Add more image file extensions as needed
    let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff"]
    return imageExtensions.contains((fullPath as NSString).pathExtension.lowercased())
  }
  
  var iconName: String {
    isLeaf ? (isImage ? "" : "doc") : "folder"
  }
}


class FileHierarchy: ObservableObject {
  @Published var rootNodes: [FileNode]
  
  init(rootPath: String) {
    self.rootNodes = FileHierarchy.loadFiles(from: rootPath)
  }
  
  static func loadFiles(from directory: String) -> [FileNode] {
    let fileManager = FileManager.default
    do {
      let items = try fileManager.contentsOfDirectory(atPath: directory)
      return items.compactMap { item -> FileNode? in
        // Skip .DS_Store files
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
  @Binding var fileHierarchy: [FileNode]
  @Binding var selectedImage: NSImage?
  @State private var selectedNode: FileNode? // Track the selected node
  
  var body: some View {
    List(fileHierarchy, children: \.children) { node in
      HStack {
        // Display thumbnail or icon
        if node.isLeaf, node.isImage {
          Image(nsImage: thumbnailForImage(at: node.fullPath))
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
        } else {
          Image(systemName: node.iconName)
        }
        
        Text(node.name)
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
  
  private func thumbnailForImage(at path: String) -> NSImage {
    // Attempt to load the image at 'path' and resize it to create a thumbnail
    // This is a simple and naive approach; consider performance optimizations
    if let image = NSImage(contentsOfFile: path) {
      return image.resizedToMaintainAspectRatio(targetHeight: 20)//image.resized(to: thumbnailSize)
    } else {
      // Fallback to an SF Symbol
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
