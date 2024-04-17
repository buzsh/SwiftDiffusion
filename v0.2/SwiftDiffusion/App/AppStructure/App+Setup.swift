//
//  App+Setup.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import Foundation

extension SwiftDiffusionApp {
  /// Initialize app file-folder structure setup with error handling.
  func setupAppFileStructure() {
    AppFileStructure.setup { error, failedUrl in
      if let error = error, let failedUrl = failedUrl {
        Debug.log("Failed to create directory at \(failedUrl): \(error)")
      } else if let error = error {
        Debug.log("Error: \(error)")
      } else {
        Debug.log("Successfully initialized application file structure.")
      }
    }
    AppFileStructure.setupDocuments { error, failedUrl in
      if let error = error, let failedUrl = failedUrl {
        Debug.log("Failed to create directory at \(failedUrl): \(error)")
      } else if let error = error {
        Debug.log("Error: \(error)")
      } else {
        Debug.log("Successfully initialized application documents structure.")
      }
    }
  }
}
