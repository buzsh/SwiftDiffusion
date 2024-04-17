//
//  AppDocuments.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import Foundation

extension Constants.FileStructure {
  static let AppDocumentsUrl: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
  static let AppDocumentsFolderName = "SwiftDiffusion"
}

/// App directories and their associated URLs
enum AppDocuments: String, CaseIterable {
  // output images
  case documents    = "SwiftDiffusion"
  case txt2img      = "SwiftDiffusion/txt2img"
}

extension AppDocuments {
  /// `URL` to the AppDirectory case (if it exists)
  var url: URL? {
    guard let appDocumentsUrl = Constants.FileStructure.AppDocumentsUrl else {
      Debug.log("Error: Unable to find Documents directory.")
      return nil
    }
    return appDocumentsUrl.appendingPathComponent(self.rawValue)
  }
}

extension AppFileStructure {
  static func setupDocuments(completion: @escaping (Error?, URL?) -> Void) {
    for directoryPath in AppDocuments.allCases {
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
