//
//  UserSettings+URLs.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import Foundation

struct AutomaticConfig {
  
  enum DefaultFilePaths: String {
    case webuiShell = "webui.sh"
  }
  
  enum DefaultModelDirectory: String {
    case stableDiffusion  = "models/Stable-diffusion"
    case lora             = "models/Lora"
    case vae              = "models/VAE"
  }
  
}

extension UserSettings {
  func resetDefaultPathsToEmpty() {
    webuiShellPath = ""
    stableDiffusionModelsPath = ""
    loraDirectoryPath = ""
    vaeDirectoryPath = ""
  }
  func setDefaultPathsForEmptySettings() {
    let automaticAbsolutePath = automaticDirectoryPath + "/"
    
    if webuiShellPath.isEmpty {
      webuiShellPath = automaticAbsolutePath + AutomaticConfig.DefaultFilePaths.webuiShell.rawValue
    }
    if stableDiffusionModelsPath.isEmpty {
      stableDiffusionModelsPath = automaticAbsolutePath + AutomaticConfig.DefaultModelDirectory.stableDiffusion.rawValue
    }
    if loraDirectoryPath.isEmpty {
      loraDirectoryPath = automaticAbsolutePath + AutomaticConfig.DefaultModelDirectory.lora.rawValue
    }
    if vaeDirectoryPath.isEmpty {
      vaeDirectoryPath = automaticAbsolutePath + AutomaticConfig.DefaultModelDirectory.lora.rawValue
    }
    
    Debug.log("automaticAbsolutePath: \(automaticAbsolutePath)")
    Debug.log("  > webuiShellPath: \(webuiShellPath)")
    Debug.log("  > stableDiffusionModelsPath: \(stableDiffusionModelsPath)")
    Debug.log("  > loraDirectoryPath: \(loraDirectoryPath)")
    Debug.log("  > vaeDirectoryPath: \(vaeDirectoryPath)")
  }
}

extension UserSettings {
  func modelDirectoryUrl<T>(forType type: T.Type) -> URL? {
    let path: String?
    
    switch type {
    case is LoraModel.Type: path = loraDirectoryPath
    case is VaeModel.Type:  path = vaeDirectoryPath
    default:
      path = nil
    }
    guard let directoryPath = path, let url = directoryUrl(forPath: directoryPath) else { return nil }
    return ensureModelDirectoryExists(at: url)
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
  
  func ensureModelDirectoryExists(at url: URL) -> URL? {
    if !FileManager.default.fileExists(atPath: url.path) {
      do {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
      } catch {
        Debug.log("Failed to create directory: \(error)")
        return nil
      }
    }
    return url
  }
  
  var stableDiffusionModelsDirectoryUrl: URL? {
    return directoryUrl(forPath: stableDiffusionModelsPath)
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
