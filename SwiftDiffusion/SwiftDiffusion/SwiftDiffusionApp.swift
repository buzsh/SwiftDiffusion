//
//  SwiftDiffusionApp.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 4/17/24.
//

import SwiftUI
import SwiftData

@main
struct SwiftDiffusionApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(sharedModelContainer)
  }
  
  /// SwiftData (sqlite3) shared model container.
  var sharedModelContainer: ModelContainer = {
    guard let storeUrl = AppConfig.FileStructure.storeUrl else {
      fatalError("Failed to initialize store URL. Check application support directories and permissions.")
    }
    
    let schema = Schema([
      Item.self,
    ])
    
    let modelConfiguration = ModelConfiguration(AppConfig.modelConfigurationName, schema: schema, url: storeUrl, allowsSave: true)
    
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
}
