//
//  FileStructure.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 4/17/24.
//

import Foundation

extension AppConfig.FileStructure {
  private static let SupportFolderName = AppConfig.name
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
