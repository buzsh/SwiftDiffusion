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
  ///
  /// - If the directory exists: return the URL to said directory
  /// - If the directory does not exist: create the directory and return the URL to the newly created directory
  ///
  /// ## Usage
  /// ```swift
  /// do {
  ///   try FileUtility.ensureDirectoryExists(at: directoryUrl)
  /// } catch {
  ///   completion(error, directoryUrl)
  /// }
  /// ```
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

