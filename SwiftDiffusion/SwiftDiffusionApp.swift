//
//  SwiftDiffusionApp.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import Cocoa
import SwiftUI

@main
struct SwiftDiffusionApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}



class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationWillTerminate(_ notification: Notification) {
    ScriptManager.shared.terminateScript { result in
        switch result {
        case .success(let message):
            print(message)
        case .failure(let error):
            print("Error: \(error.localizedDescription)")
        }
    }
  }
}
