//
//  FileUtility.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import Foundation

enum FileUtilityError: Error {
  case directoryCreationFailed(url: URL, underlyingError: Error)
  case urlConstructionFailed
}

struct FileUtility {
  
  
  /// Ensures a directory exists at the specified URL, throwing an error if creation fails.
  static func ensureDirectoryExists(at url: URL) throws {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: url.path) {
      do {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      } catch {
        throw FileUtilityError.directoryCreationFailed(url: url, underlyingError: error)
      }
    }
  }
}

