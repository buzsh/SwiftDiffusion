//
//  ConfigFileManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import Foundation

struct ConfigFileManager {
  let scriptPath: String
  
  var configFilePath: String? {
    guard let scriptDirectory = URL(string: scriptPath)?.deletingLastPathComponent().absoluteString.removingPercentEncoding else {
      return nil
    }
    return scriptDirectory.appending("/config.json")
  }
  
  func disableLaunchBrowser(completion: @escaping (Result<String, Error>) -> Void) {
    guard let configFilePath = configFilePath else {
      completion(.failure(NSError(domain: "ConfigFileManagerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Script directory not found."])))
      return
    }
    
    do {
      var configContent = try String(contentsOfFile: configFilePath, encoding: .utf8)
      let pattern = "\"auto_launch_browser\":\\s*\"[^\"]*\""
      if let range = configContent.range(of: pattern, options: .regularExpression) {
        let originalLine = String(configContent[range])
        configContent = configContent.replacingOccurrences(of: pattern, with: "\"auto_launch_browser\": \"Disable\"", options: .regularExpression)
        try configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        completion(.success(originalLine))
      } else {
        completion(.failure(NSError(domain: "ConfigFileManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "auto_launch_browser line not found in config.json."])))
      }
    } catch {
      completion(.failure(error))
    }
  }
  
  func restoreLaunchBrowser(originalLine: String, completion: @escaping (Result<Void, Error>) -> Void) {
    guard let configFilePath = configFilePath else {
      completion(.failure(NSError(domain: "ConfigFileManagerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Script directory not found."])))
      return
    }
    
    do {
      var configContent = try String(contentsOfFile: configFilePath, encoding: .utf8)
      let pattern = "\"auto_launch_browser\":\\s*\"Disable\""
      if configContent.range(of: pattern, options: .regularExpression) != nil {
        configContent = configContent.replacingOccurrences(of: pattern, with: originalLine, options: .regularExpression)
        try configContent.write(toFile: configFilePath, atomically: true, encoding: .utf8)
        completion(.success(()))
      } else {
        completion(.failure(NSError(domain: "ConfigFileManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "auto_launch_browser disabled line not found in config.json."])))
      }
    } catch {
      completion(.failure(error))
    }
  }
}
