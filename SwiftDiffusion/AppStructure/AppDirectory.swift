//
//  AppDirectory.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import Foundation

extension Constants.FileStructure {
  // Can custom set this variable if user wants custom application directory path
  static let AppSupportUrl: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
  static let AppSupportFolderName = "SwiftDiffusion"
  static let AppSwiftDataFileName = "default.store"
}

/// App directories and their associated URLs
enum AppDirectory: String, CaseIterable {
  // UserFiles: models, loras, embeddings, etc.
  case userFiles    = "UserFiles"
  case models       = "UserFiles/Models"
  case coreMl       = "UserFiles/Models/CoreML"
  case python       = "UserFiles/Models/Python"
  // UserData: local database, saved prompt media, etc.
  case userData     = "UserData"
  case promptMedia  = "UserData/PromptMedia"
}
