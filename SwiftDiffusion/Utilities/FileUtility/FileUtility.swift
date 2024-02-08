//
//  FileUtility.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import Foundation

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
