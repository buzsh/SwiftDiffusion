//
//  AppRelauncherUtility.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/21/24.
//

import Foundation
import AppKit

class AppRelauncherUtility {
  private let scriptPath: String = NSTemporaryDirectory() + "relaunch.sh"
  
  init() {
    let scriptContent = """
        #!/bin/bash
        
        # Wait until the application quits
        while ps -p $1 > /dev/null; do sleep 1; done
        
        sleep 2  # Increase this delay if needed
        
        # Launch the application again
        open -a "$2"
        """
    
    do {
      try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
      try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
    } catch {
      Debug.log("Failed to create or set permissions for script: \(error)")
    }
  }
  
  func relaunchApplication() {
    let process = Process()
    let bundleID = Bundle.main.bundleIdentifier ?? "com.buzsh.SwiftDiffusion"
    
    Debug.log("relaunchApplication with bundleID: \(bundleID)")
    
    let scriptURL = URL(fileURLWithPath: scriptPath)  // Corrected method to form URL
    
    process.launchPath = "/bin/bash"
    process.arguments = [scriptURL.path, String(ProcessInfo.processInfo.processIdentifier), bundleID]
    
    do {
      try process.run()
    } catch {
      Debug.log("Failed to launch script: \(error)")
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      NSApplication.shared.terminate(nil)
    }
  }
}
