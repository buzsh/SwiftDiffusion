//
//  ScriptSetupHelper.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

/// Helps with setting up script paths and directories.
struct ScriptSetupHelper {
  /// Calculates and returns script path components.
  /// - Parameter scriptPath: The full path to the script.
  /// - Returns: A tuple containing the script path, directory, and name, or nil if the path is empty.
  static func setupScriptPath(_ scriptPath: String?) -> (String, String, String)? {
    guard let scriptPath = scriptPath, !scriptPath.isEmpty else { return nil }
    let scriptDirectory = URL(fileURLWithPath: scriptPath).deletingLastPathComponent().path
    let scriptName = URL(fileURLWithPath: scriptPath).lastPathComponent
    return (scriptPath, scriptDirectory, scriptName)
  }
}
