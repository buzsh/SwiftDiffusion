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
  var sidebarModel: SidebarModel
  var scriptManager = ScriptManager.shared
  let pastableService = PastableService.shared
  let updateManager = UpdateManager()
  let checkpointsManager = CheckpointsManager()
  let currentPrompt = PromptModel()
  let loraModelsManager = ModelManager<LoraModel>()
  let vaeModelsManager = ModelManager<VaeModel>()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .frame(minWidth: 720, idealWidth: 1200, maxWidth: .infinity,
               minHeight: 500, idealHeight: 860, maxHeight: .infinity)
        .environmentObject(scriptManager)
        .environmentObject(pastableService)
        .environmentObject(updateManager)
        .environmentObject(sidebarModel)
        .environmentObject(checkpointsManager)
        .environmentObject(currentPrompt)
        .environmentObject(loraModelsManager)
        .environmentObject(vaeModelsManager)
        .onAppear {
          NSWindow.allowsAutomaticWindowTabbing = false
        }
    }
    .modelContainer(modelContainer)
    .windowToolbarStyle(.unified(showsTitle: false))
    .commands {
      CommandGroup(replacing: .newItem) {}
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
        MenuButton(title: "Copy Generation Data", symbol: .copy, action: {
          sidebarModel.selectedSidebarItem?.prompt?.copyMetadataToClipboard()
        })
        MenuButton(title: "Paste Generation Data", symbol: .paste, action: {
          pastableService.newWorkspaceItemFromParsedPasteboard(sidebarModel: sidebarModel, checkpoints: checkpointsManager.models, vaeModels: vaeModelsManager.models)
        })
      }
    }
  }
  
  init() {
    let fileManager = FileManager.default
    guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      fatalError("Application Support directory not found.")
    }
    let storeURL = appSupportURL
      .appendingPathComponent(Constants.FileStructure.AppSupportFolderName)
      .appendingPathComponent("UserData").appendingPathComponent("LocalDatabase")
      .appendingPathComponent(Constants.FileStructure.AppSwiftDataFileName)
    
    let subfolderURL = storeURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: subfolderURL.path) {
      try! fileManager.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
    }
    
    do {
      modelContainer = try ModelContainer(for: SidebarFolder.self, configurations: ModelConfiguration(url: storeURL))
    } catch {
      fatalError("Failed to configure SwiftData container: \(error)")
    }
    modelContainer.mainContext.autosaveEnabled = true
    sidebarModel = SidebarModel(modelContext: modelContainer.mainContext)
    setupAppFileStructure()
  }
}
