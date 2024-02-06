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
  case main, console, settings
  
  var title: String {
    switch self {
    case .main: return "Home"
    case .console: return "Console"
    case .settings: return "Settings"
    }
  }
}

extension ViewManager: Hashable, Identifiable {
  var id: Self { self }
}

struct ContentView: View {
  // Toolbar
  @State private var showingSettingsView = false
  // Main
  @ObservedObject var mainViewModel: MainViewModel
  // Console
  @ObservedObject var scriptManager: ScriptManager
  @Binding var scriptPathInput: String
  @Binding var fileOutputDir: String
  // Views
  @State private var selectedView: ViewManager = .main
  // Detail
  @StateObject private var fileHierarchy = FileHierarchy(rootPath: "")
  @State private var selectedImage: NSImage? = NSImage(named: "DiffusionPlaceholder")
  @AppStorage("lastSelectedImagePath") private var lastSelectedImagePath: String = ""
  
  
  
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
      // MainView (prompt controller, console, etc.)
      switch selectedView {
      case .main:
        MainView(prompt: mainViewModel)
      case .console:
        ConsoleView(scriptManager: scriptManager, scriptPathInput: $scriptPathInput)
      case .settings:
        SettingsView(scriptPathInput: $scriptPathInput, fileOutputDir: $fileOutputDir)
      }
    } detail: {
      // Image, FileSelect DetailView
      DetailView(fileHierarchyObject: fileHierarchy, selectedImage: $selectedImage, lastSelectedImagePath: $lastSelectedImagePath)
    }
    .background(VisualEffectBlurView(material: .headerView, blendingMode: .behindWindow))
    .onAppear {
      scriptPathInput = scriptManager.scriptPath ?? ""
      fileHierarchy.rootPath = fileOutputDir
      Task {
        await fileHierarchy.refresh()
        await loadLastSelectedImage()
      }
    }
    .onChange(of: fileOutputDir) {
      fileHierarchy.rootPath = fileOutputDir
      Task {
        await fileHierarchy.refresh()
      }
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
          showingSettingsView = true
        }) {
          Image(systemName: "gear")
        }
      }
    }
    .sheet(isPresented: $showingSettingsView) {
      SettingsView(scriptPathInput: $scriptPathInput, fileOutputDir: $fileOutputDir)
    }
  }
  
  private func loadLastSelectedImage() async {
    if !lastSelectedImagePath.isEmpty, let image = NSImage(contentsOfFile: lastSelectedImagePath) {
      await MainActor.run {
        self.selectedImage = image
      }
    }
  }
  
}

/*
 #Preview {
 ContentView()
 }
 */
