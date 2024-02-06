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
        } else if NSImage(named: "DiffusionPlaceholder") != nil {
          Image(nsImage: NSImage(named: "DiffusionPlaceholder")!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          // fallback dark gray box
          Rectangle()
            .foregroundColor(.gray)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        Text(node.name)
        Spacer()
      }
      .padding(5) // Add some padding to make the highlight more visible
      .background(self.selectedNode == node ? Color.blue : Color.clear) // Highlight if selected
      .cornerRadius(5) // Rounded corners for the highlight
      .onTapGesture {
        self.selectNode(node)
      }
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
