//
//  WindowManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import Cocoa
import SwiftUI

class WindowManager: NSObject, ObservableObject {
  static let shared = WindowManager()
  
  private var updatesWindow: NSWindow?
  private var settingsWindow: NSWindow?
  private var modelsManagerWindow: NSWindow?
  
  override private init() { }
  
  func showUpdatesWindow() {
    // check if the window already exists to avoid creating multiple instances
    if updatesWindow == nil {
      updatesWindow = NSWindow(
        contentRect: NSRect(x: 20, y: 20, width: 480, height: 300),
        styleMask: [.titled, .closable, .resizable],
        backing: .buffered, defer: false)
      updatesWindow?.center()
      updatesWindow?.contentView = NSHostingView(rootView: UpdatesView())
      updatesWindow?.title = "Check for Updates"
      
      updatesWindow?.isReleasedWhenClosed = false
      updatesWindow?.delegate = self
    }
    updatesWindow?.makeKeyAndOrderFront(nil)
  }
  
  func showSettingsWindow(withPreferenceStyle: Bool = false) {
    if settingsWindow == nil {
      settingsWindow = NSWindow(
        contentRect: NSRect(x: 40, y: 40, width: Constants.WindowSize.Settings.defaultWidth, height: Constants.WindowSize.Settings.defaultHeight),
        styleMask: [.titled, .closable, .resizable],
        backing: .buffered, defer: false)
      settingsWindow?.center()
      settingsWindow?.setFrameAutosaveName("Settings")
      settingsWindow?.contentView = NSHostingView(rootView: SettingsView())
      settingsWindow?.title = "Settings"
      
      settingsWindow?.isReleasedWhenClosed = false
      settingsWindow?.delegate = self
      
      if withPreferenceStyle {
        if #available(macOS 11.0, *) {
          settingsWindow?.toolbarStyle = .preference
          settingsWindow?.titlebarAppearsTransparent = false
          settingsWindow?.titleVisibility = .visible
        }
      }
    }
    settingsWindow?.makeKeyAndOrderFront(nil)
  }
  
  func showModelsManagerWindow(scriptManager: ScriptManager) {
    // check if the window already exists to avoid creating multiple instances
    if modelsManagerWindow == nil {
      modelsManagerWindow = NSWindow(
        contentRect: NSRect(x: 20, y: 20, width: Constants.WindowSize.Settings.defaultWidth, height: Constants.WindowSize.Settings.defaultHeight),
        styleMask: [.titled, .closable, .resizable],
        backing: .buffered, defer: false)
      modelsManagerWindow?.center()
      modelsManagerWindow?.contentView = NSHostingView(rootView: ModelManagerView(scriptManager: scriptManager))
      modelsManagerWindow?.title = "Models"
      
      modelsManagerWindow?.isReleasedWhenClosed = false
      modelsManagerWindow?.delegate = self
    }
    modelsManagerWindow?.makeKeyAndOrderFront(nil)
  }
}

extension WindowManager: NSWindowDelegate {
  func windowWillClose(_ notification: Notification) {
    // Release the window when it's closed to free up memory
    if let window = notification.object as? NSWindow {
      if window == updatesWindow {
        updatesWindow = nil
      } else if window == settingsWindow {
        settingsWindow = nil
      } else if window == modelsManagerWindow {
        modelsManagerWindow = nil
      }
    }
  }
}
