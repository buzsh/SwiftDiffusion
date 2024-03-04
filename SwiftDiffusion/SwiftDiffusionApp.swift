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
  var modelContainer: ModelContainer
  var scriptManager = ScriptManager.shared
  let updateManager = UpdateManager()
  let sidebarModel = SidebarModel()
  let checkpointsManager = CheckpointsManager()
  let loraModelsManager = ModelManager<LoraModel>()
  let vaeModelsManager = ModelManager<VaeModel>()
  
  init() {
    let fileManager = FileManager.default
    guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      fatalError("Application Support directory not found.")
    }
    let storeURL = appSupportURL
      .appendingPathComponent(Constants.FileStructure.AppSupportFolderName)
      .appendingPathComponent("UserData").appendingPathComponent("LocalDatabase")
      .appendingPathComponent("LocalDataTest1") // Constants.FileStructure.AppSwiftDataFileName
    
    let subfolderURL = storeURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: subfolderURL.path) {
      try! fileManager.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
    }
    
    do {
      modelContainer = try ModelContainer(for: SidebarItem.self, SidebarFolder.self, configurations: ModelConfiguration(url: storeURL))
    } catch {
      fatalError("Failed to configure SwiftData container: \(error)")
    }
    setupAppFileStructure()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 720, idealWidth: 900, maxWidth: .infinity,
               minHeight: 500, idealHeight: 800, maxHeight: .infinity)
        .environmentObject(scriptManager)
        .environmentObject(updateManager)
        .environmentObject(sidebarModel)
        .environmentObject(checkpointsManager)
        .environmentObject(loraModelsManager)
        .environmentObject(vaeModelsManager)
    }
    .modelContainer(modelContainer)
    .windowToolbarStyle(.unified(showsTitle: false))
    .commands {
      CommandGroup(after: .appInfo) {
        Divider()
        
        Button("Check for Updates...") {
          WindowManager.shared.showUpdatesWindow(updateManager: updateManager)
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
          guard let prompt = sidebarModel.selectedSidebarItem?.prompt else { return }
          prompt.copyMetadataToClipboard()
        }
        .keyboardShortcut("C", modifiers: [.command, .shift])
        /*
        Button("Paste Generation Data") {
          if let selectedSidebarItem = sidebarModel.selectedSidebarItem {
            selectedSidebarItem.prompt.pasteMetadataFromClipboard()
          }
        }
        .keyboardShortcut("V", modifiers: [.command, .shift])
         */
      }
    }
  }
}
