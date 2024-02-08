//
//  FileUtility.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import Foundation

extension Constants.FileStructure {
  static let ApplicationSupportFolderName = "SwiftDiffusion"
  static let ApplicationSwiftDataFileName = "default.store"
  // UserFiles: models, loras, embeddings, etc.
  static var userFilesDirUrl, userModelsDirUrl, coreMlModelsDirUrl, pythonModelsDirUrl: URL?
  // UserData: local database, saved prompt media, etc.
  static var userDataDirUrl, promptMediaDirUrl: URL?
}

enum DirectoryPath: String, CaseIterable {
  // UserFiles: models, loras, embeddings, etc.
  case userFiles    = "UserFiles"
  case models       = "UserFiles/Models"
  case coreML       = "UserFiles/Models/CoreML"
  case python       = "UserFiles/Models/Python"
  // UserData: local database, saved prompt media, etc.
  case userData     = "UserData"
  case promptMedia  = "UserData/PromptMedia"
  
  // Computed property to directly get the URL for a directory path
  var url: URL? {
    guard let appSupportUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      Debug.log("Error: Unable to find Application Support directory.")
      return nil
    }
    let baseFolderUrl = appSupportUrl.appendingPathComponent(Constants.FileStructure.ApplicationSupportFolderName)
    return baseFolderUrl.appendingPathComponent(self.rawValue)
  }
}

struct FileUtility {
  /// Setup application file structure if needed using the enum for directory paths
  static func setupAppFileStructureIfNeeded() {
    DirectoryPath.allCases.forEach { directoryPath in
      guard let directoryUrl = directoryPath.url else { return }
      _ = createDirectoryIfNeeded(at: directoryUrl, withFileManager: FileManager.default)
    }
  }
  
  /// Creates a directory at the specified URL if it does not exist.
  private static func createDirectoryIfNeeded(at url: URL, withFileManager fileManager: FileManager) -> URL {
    if !fileManager.fileExists(atPath: url.path) {
      do {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      } catch {
        Debug.log("Error creating directory at \(url.path): \(error)")
      }
    }
    return url
  }
}
