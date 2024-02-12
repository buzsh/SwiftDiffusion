//
//  UserSettings+URLs.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import Foundation

extension UserSettings {
  
  var stableDiffusionModelsDirectoryUrl: URL? {
    guard !stableDiffusionModelsPath.isEmpty else { return nil }
    let pathUrl = URL(fileURLWithPath: stableDiffusionModelsPath)
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: stableDiffusionModelsPath, isDirectory: &isDir), isDir.boolValue {
      return pathUrl
    } else {
      return nil
    }
  }
  
  var outputDirectoryUrl: URL? {
    let fileManager = FileManager.default
    var directoryUrl: URL?
    
    if !outputDirectoryPath.isEmpty {
      directoryUrl = URL(fileURLWithPath: outputDirectoryPath)
    } else if let documentsDirectoryUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
      directoryUrl = documentsDirectoryUrl.appendingPathComponent("SwiftDiffusion")
    }
    
    if let url = directoryUrl {
      do {
        try FileUtility.ensureDirectoryExists(at: url)
        return url
      } catch {
        Debug.log("Failed to ensure directory exists: \(error.localizedDescription)")
        return nil
      }
    }
    
    return nil
  }
  
}
