//
//  UserSettings+URLs.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import Foundation

extension UserSettings {
  
  func modelDirectoryUrl<T>(forType type: T.Type) -> URL? {
    switch type {
    case is PythonCheckpointModel.Type:
      return directoryUrl(forPath: stableDiffusionModelsPath)
    case is LoraModel.Type:
      return directoryUrl(forPath: loraDirectoryPath)
    default:
      return nil
    }
  }
  
  func directoryUrl(forPath path: String) -> URL? {
    guard !path.isEmpty else { return nil }
    let pathUrl = URL(fileURLWithPath: path)
    var isDir: ObjCBool = false
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
      return pathUrl
    } else {
      return nil
    }
  }
  
  var stableDiffusionModelsDirectoryUrl: URL? {
    return directoryUrl(forPath: stableDiffusionModelsPath)
  }
  
  var loraDirectoryUrl: URL? {
    return directoryUrl(forPath: loraDirectoryPath)
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
