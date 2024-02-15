//
//  SwiftDiffusionApp.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI
import SwiftData

@main
struct SwiftDiffusionApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject var scriptManager = ScriptManager.shared
  
  let currentPrompt = PromptModel()
  let modelManangerViewModel = ModelManagerViewModel()
  let sidebarViewModel = SidebarViewModel()
  
  var modelContainer: ModelContainer
  
  init() {
    let fileManager = FileManager.default
    guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      fatalError("Application Support directory not found.")
    }
    let storeURL = appSupportURL
      .appendingPathComponent(Constants.FileStructure.AppSupportFolderName)
      .appendingPathComponent("UserData").appendingPathComponent("Local")
      .appendingPathComponent(Constants.FileStructure.AppSwiftDataFileName)
    
    // Ensure the directory exists before initializing the ModelContainer
    let subfolderURL = storeURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: subfolderURL.path) {
      try! fileManager.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
    }
    
    do {
      // Initialize the ModelContainer with your model types
      modelContainer = try ModelContainer(for: SidebarItem.self, SidebarFolder.self, configurations: ModelConfiguration(url: storeURL))
    } catch {
      fatalError("Failed to configure SwiftData container: \(error)")
    }
    
    setupAppFileStructure()
    modelManangerViewModel.startObservingModelDirectories()
  }
  
  
  var body: some Scene {
    WindowGroup {
      ContentView(scriptManager: scriptManager)
        .frame(minWidth: 720, idealWidth: 900, maxWidth: .infinity,
               minHeight: 500, idealHeight: 800, maxHeight: .infinity)
        .environmentObject(currentPrompt)
        .environmentObject(modelManangerViewModel)
        .environmentObject(sidebarViewModel)
    }
    .modelContainer(modelContainer)
    .windowToolbarStyle(.unified(showsTitle: false))
    .commands {
      CommandGroup(after: .appInfo) {
        Divider()
        
        Button("Check for Updates...") {
          WindowManager.shared.showUpdatesWindow()
        }
        .keyboardShortcut("U", modifiers: [.command])
        
        Divider()
        
        Button("Settings...") {
          WindowManager.shared.showSettingsWindow()
        }
        .keyboardShortcut(",", modifiers: [.command])
      }
    }
    .commands {
      CommandMenu("Prompt") {
        Button("Copy Generation Data") {
          currentPrompt.copyMetadataToClipboard()
        }
      }
    }
  }
}
