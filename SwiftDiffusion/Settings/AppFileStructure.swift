//
//  AppFileStructure.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import Foundation

extension Constants.FileStructure {
  static let ApplicationSupportFolderName = "SwiftDiffusion"
  static let ApplicationSwiftDataFileName = "default.store"
}

enum DirectoryPath: String, CaseIterable {
  // UserFiles: models, loras, embeddings, etc.
  case userFiles    = "UserFiles"
  case models       = "UserFiles/Models"
  case coreMl       = "UserFiles/Models/CoreML"
  case python       = "UserFiles/Models/Python"
  // UserData: local database, saved prompt media, etc.
  case userData     = "UserData"
  case promptMedia  = "UserData/PromptMedia"
  
  // computed property to directly get the URL for a directory path
  var url: URL? {
    guard let appSupportUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      Debug.log("Error: Unable to find Application Support directory.")
      return nil
    }
    let baseFolderUrl = appSupportUrl.appendingPathComponent(Constants.FileStructure.ApplicationSupportFolderName)
    return baseFolderUrl.appendingPathComponent(self.rawValue)
  }
}

extension FileUtility.AppFileStructure {
  /// Attempts to ensure that the required directory structure for the application exists.
  /// Calls the completion handler with an error and the URL of the directory that failed to be created, if applicable.
  static func setup(completion: @escaping (Error?, URL?) -> Void) {
    for directoryPath in DirectoryPath.allCases {
      guard let directoryUrl = directoryPath.url else {
        completion(FileUtilityError.urlConstructionFailed, nil) // failed to construct URL
        return
      }
      
      do {
        try FileUtility.ensureDirectoryExists(at: directoryUrl)
        // success for this directory, continue to the next
      } catch {
        completion(error, directoryUrl) // Return the error and the URL that caused it
        return
      }
    }
    
    completion(nil, nil) // indicate success if all directories were ensured without errors
  }
}

