//
//  AppFileStructure.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import Foundation

extension AppDirectory {
  /// `URL` to the AppDirectory case (if it exists)
  var url: URL? {
    guard let appSupportUrl = Constants.FileStructure.AppSupportUrl else {
      Debug.log("Error: Unable to find Application Support directory.")
      return nil
    }
    let baseFolderUrl = appSupportUrl.appendingPathComponent(Constants.FileStructure.AppSupportFolderName)
    return baseFolderUrl.appendingPathComponent(self.rawValue)
  }
}
/// Core app file-folder structure setup and configuration.
struct AppFileStructure {
  /// Attempts to ensure that the required directory structure for the application exists.
  /// Calls the completion handler with an error and the URL of the directory that failed to be created, if applicable.
  ///
  /// ## Usage
  /// ```swift
  /// FileUtility.AppFileStructure.setup { error, failedUrl in
  /// if let error = error, let failedUrl = failedUrl {
  ///   print("Failed to create directory at \(failedUrl): \(error)")
  /// } else if let error = error {
  ///   print("Error: \(error)")
  /// } else {
  ///   print("Success")
  /// }
  /// ```
  static func setup(completion: @escaping (Error?, URL?) -> Void) {
    for directoryPath in AppDirectory.allCases {
      guard let directoryUrl = directoryPath.url else {
        completion(FileUtilityError.urlConstructionFailed, nil)
        return
      }
      do {
        try FileUtility.ensureDirectoryExists(at: directoryUrl)
      } catch {
        completion(error, directoryUrl)
        return
      }
    }
    // indicate success if all directories were ensured without errors
    completion(nil, nil)
  }
}

extension AppFileStructure {
  
  
  
}
