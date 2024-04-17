//
//  SwiftDataDemoApp.swift
//  SwiftDataDemo
//
//  Created by Justin Bush on 4/17/24.
//

import SwiftUI
import SwiftData

@main
struct SwiftDataDemoApp: App {
  var sharedModelContainer: ModelContainer = {
    guard let storeUrl = AppConfig.FileStructure.storeUrl else {
      fatalError("Failed to initialize store URL. Check application support directories and permissions.")
    }
    
    let schema = Schema([
      Item.self,
    ])
    
    let modelConfiguration = ModelConfiguration("SwiftDataDemoName", schema: schema, url: storeUrl, allowsSave: true)
    
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(sharedModelContainer)
  }
}

struct Constants {
  
  struct Api {}
  struct App {}
  struct CommandLine {}
  struct Debug {}
  struct Delays {}
  struct FileStructure {}
  struct FileTypes {}
  struct Keys {}
  struct Layout {}
  struct Parsing {}
  struct PromptOptions {}
  struct Sidebar {}
  struct WindowSize {}
  
}

extension Constants.App {
  static let name = "SwiftDataDemo"
}

extension Constants.CommandLine {
  static let zshPath = "/bin/zsh"
  static let zshUrl = URL(fileURLWithPath: zshPath)
}



struct AppConfig {
  
  struct FileStructure {}
  
}

extension AppConfig.FileStructure {
  private static let SupportFolderName = "SwiftDataDemo"
  private static let UserDataFolderName = "UserData"
  private static let LocalDatabaseFolderName = "Database"
  private static let SwiftDataFileName = "Local.store"
  
  static var appSupportUrl: URL? = {
    guard let appSupportUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      fatalError("Application Support directory not found.")
    }
    return appSupportUrl
  }()
  
  private static func buildStoreUrl(from appSupportUrl: URL) -> URL {
    return appSupportUrl
      .appendingPathComponent(SupportFolderName)
      .appendingPathComponent(UserDataFolderName)
      .appendingPathComponent(LocalDatabaseFolderName)
      .appendingPathComponent(SwiftDataFileName)
  }
  
  static var storeUrl: URL? {
    guard let appSupportUrl = appSupportUrl else { return nil }
    let storeUrl = buildStoreUrl(from: appSupportUrl)
    
    do {
      return try storeUrl.ensureParentDirectoriesExists()
    } catch {
      print("Failed to create directories for store URL: \(error)")
      return nil
    }
  }
}

extension URL {
  func ensureParentDirectoriesExists() throws -> URL {
    let directoryPath = self.deletingLastPathComponent()
    do {
      try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
      return self
    } catch {
      throw error
    }
  }
}
