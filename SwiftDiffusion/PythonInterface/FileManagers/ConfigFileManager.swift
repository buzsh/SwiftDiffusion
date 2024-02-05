//
//  ConfigFileManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import Foundation

extension Constants {
  struct ConfigFile {
    static let pathToConfigJson = "/config.json"
    static let autoLaunchBrowserPattern = "\"auto_launch_browser\":\\s*\"[^\"]*\""
    static let autoLaunchBrowserDisabled = "\"auto_launch_browser\": \"Disable\""
    static let autoLaunchBrowserDisabledPattern = "\"auto_launch_browser\":\\s*\"Disable\""
  }
}

struct ConfigFileManager {
  let scriptPath: String
  
  var configFilePath: String? {
    guard let scriptDirectory = URL(string: scriptPath)?.deletingLastPathComponent().absoluteString.removingPercentEncoding else {
      return nil
    }
    return scriptDirectory.appending(Constants.ConfigFile.pathToConfigJson)
  }
  
  func disableLaunchBrowser(completion: @escaping (Result<String, Error>) -> Void) {
    guard let configFilePath = configFilePath else {
      completion(.failure(NSError(domain: "ConfigFileManagerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Script directory not found."])))
      return
    }
    
    do {
      var configContent = try String(contentsOfFile: configFilePath, encoding: .utf8)
      let pattern = Constants.ConfigFile.autoLaunchBrowserPattern
      if let range = configContent.range(of: pattern, options: .regularExpression) {
        let originalLine = String(configContent[range])
        configContent = configContent.replacingOccurrences(of: pattern, with: Constants.ConfigFile.autoLaunchBrowserDisabled, options: .regularExpression)
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
      let pattern = Constants.ConfigFile.autoLaunchBrowserDisabledPattern
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
