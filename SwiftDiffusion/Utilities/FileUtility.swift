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
  
  static let userFilesDir = "UserFiles"
  static let relModelsDir = userFilesDir.appending("/").appending("Models") // > UserFiles/Models
  static let relCoreMlDir = relModelsDir.appending("/").appending("CoreML") // > UserFiles/Models/CoreML
  static let relPythonDir = relModelsDir.appending("/").appending("Python") // > UserFiles/Models/Python
  
  static var userFilesUrl: URL?
  static var userModelsUrl: URL?
  static var coreMlModelsUrl: URL?
  static var pythonModelsUrl: URL?
}

struct FileUtility {
  /// Creates user mods and backup folders if they don't already exist.
  /// It also creates a default file in the default files directory.
  static func setupAppFileStructureIfNeeded() {
    let fileManager = FileManager.default
    if let appSupportUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      Debug.log("appSupportUrl = \(appSupportUrl)")
      let baseFolderUrl = appSupportUrl.appendingPathComponent(Constants.FileStructure.ApplicationSupportFolderName)
      Debug.log("baseFolderUrl = \(baseFolderUrl)")
      Constants.FileStructure.userFilesUrl = createDirectoryIfNeeded(at: baseFolderUrl.appendingPathComponent(Constants.FileStructure.userFilesDir), withFileManager: fileManager)
      Constants.FileStructure.userModelsUrl = createDirectoryIfNeeded(at: baseFolderUrl.appendingPathComponent(Constants.FileStructure.relModelsDir), withFileManager: fileManager)
      Constants.FileStructure.coreMlModelsUrl = createDirectoryIfNeeded(at: baseFolderUrl.appendingPathComponent(Constants.FileStructure.relCoreMlDir), withFileManager: fileManager)
      Constants.FileStructure.pythonModelsUrl = createDirectoryIfNeeded(at: baseFolderUrl.appendingPathComponent(Constants.FileStructure.relPythonDir), withFileManager: fileManager)
    } else {
      Debug.log("Error: Unable to find Application Support directory.")
    }
  }
  
  /// Creates a directory at the specified URL if it does not exist.
  ///
  /// - Parameters:
  ///   - url: The URL where the directory should be created.
  ///   - fileManager: The FileManager instance to use for file operations.
  /// - Returns: The URL where the directory was created or supposed to be.
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
