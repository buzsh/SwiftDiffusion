//
//  WindowManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import Cocoa
import SwiftUI

/// `WindowManager` is responsible for managing the application's window instances such as updates, settings, and models manager windows.
/// It ensures that only one instance of each window is created and shown to the user.
class WindowManager: NSObject, ObservableObject {
  /// Shared instance of `WindowManager` for global access.
  static let shared = WindowManager()
  /// Window instance for UpdatesView.
  private var updatesWindow: NSWindow?
  /// Window instance for SettingsView.
  private var settingsWindow: NSWindow?
  /// Window instance for ModelsManagerView.
  private var checkpointManagerWindow: NSWindow?
  
  private var debugApiView: NSWindow?
  
  /// Initializes a new `WindowManager`. It is private to ensure `WindowManager` can only be accessed through its shared instance.
  override private init() { }
  
  /// Shows the updates window containing UpdatesView. If the window does not exist, it creates and configures a new window before displaying it.
  func showUpdatesWindow() {
    if updatesWindow == nil {
      updatesWindow = NSWindow(
        contentRect: NSRect(x: 20, y: 20, width: 480, height: 300),
        styleMask: [.titled, .closable, .resizable, .miniaturizable],
        backing: .buffered, defer: false)
      updatesWindow?.center()
      updatesWindow?.contentView = NSHostingView(rootView: UpdatesView())
      
      updatesWindow?.isReleasedWhenClosed = false
      updatesWindow?.delegate = self
      
      updatesWindow?.standardWindowButton(.zoomButton)?.isHidden = true
    }
    updatesWindow?.makeKeyAndOrderFront(nil)
  }
  
  /// Shows the settings window containing SettingsView. If the window does not exist, it creates and configures a new window before displaying it.
  /// - Parameter withPreferenceStyle: A Boolean value indicating whether the window should use a preferences style toolbar.
  func showSettingsWindow(withPreferenceStyle: Bool = false, withTab tab: SettingsTab? = nil) {
    if settingsWindow == nil {
      settingsWindow = NSWindow(
        contentRect: NSRect(x: 40, y: 40, width: Constants.WindowSize.Settings.defaultWidth, height: Constants.WindowSize.Settings.defaultHeight),
        styleMask: [.titled, .closable, .resizable, .miniaturizable],
        backing: .buffered, defer: false)
      settingsWindow?.center()
      settingsWindow?.setFrameAutosaveName("Settings")
      settingsWindow?.contentView = NSHostingView(rootView: SettingsView(openWithTab: tab))
      
      settingsWindow?.isReleasedWhenClosed = false
      settingsWindow?.delegate = self
      
      settingsWindow?.standardWindowButton(.zoomButton)?.isHidden = true
      
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
  
  /// Shows the models manager window containing CheckpointManagerView. If the window does not exist, it creates and configures a new window before displaying it.
  /// - Parameter scriptManager: The `ScriptManager` instance to be passed to the `CheckpointManagerView`.
  func showCheckpointManagerWindow(scriptManager: ScriptManager, currentPrompt: PromptModel, checkpointsManager: CheckpointsManager) {
    if checkpointManagerWindow == nil {
      checkpointManagerWindow = NSWindow(
        contentRect: NSRect(x: 20, y: 20, width: Constants.WindowSize.Settings.defaultWidth, height: Constants.WindowSize.Settings.defaultHeight),
        styleMask: [.titled, .closable, .resizable, .miniaturizable],
        backing: .buffered, defer: false)
      checkpointManagerWindow?.center()
      
      //let rootView = CheckpointManagerView()
      
      checkpointManagerWindow?.contentView = NSHostingView(rootView: CheckpointManagerView(scriptManager: scriptManager, currentPrompt: currentPrompt, checkpointsManager: checkpointsManager))
      
      checkpointManagerWindow?.isReleasedWhenClosed = false
      checkpointManagerWindow?.delegate = self
      
      checkpointManagerWindow?.standardWindowButton(.zoomButton)?.isHidden = true
    }
    checkpointManagerWindow?.makeKeyAndOrderFront(nil)
  }
  
  func showDebugApiWindow(scriptManager: ScriptManager, currentPrompt: PromptModel, checkpointsManager: CheckpointsManager, loraModelsManager: ModelManager<LoraModel>) {
    if checkpointManagerWindow == nil {
      checkpointManagerWindow = NSWindow(
        contentRect: NSRect(x: 20, y: 20, width: Constants.WindowSize.DebugApi.defaultWidth, height: Constants.WindowSize.DebugApi.defaultHeight),
        styleMask: [.titled, .closable, .resizable, .miniaturizable],
        backing: .buffered, defer: false)
      checkpointManagerWindow?.center()
      
      let rootView = DebugApiView()
                  .environmentObject(scriptManager)
                  .environmentObject(checkpointsManager)
                  .environmentObject(currentPrompt)
                  .environmentObject(loraModelsManager)
              
     checkpointManagerWindow?.contentView = NSHostingView(rootView: rootView)
      
      
      
      
      checkpointManagerWindow?.isReleasedWhenClosed = false
      checkpointManagerWindow?.delegate = self
      
      checkpointManagerWindow?.standardWindowButton(.zoomButton)?.isHidden = true
    }
    checkpointManagerWindow?.makeKeyAndOrderFront(nil)
  }
}

extension WindowManager: NSWindowDelegate {
  /// Handles window close events by setting the corresponding window instance to nil, effectively releasing it.
  /// - Parameter notification: The notification object containing information about the window close event.
  func windowWillClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow {
      switch window {
      case updatesWindow:
        updatesWindow = nil
      case settingsWindow:
        settingsWindow = nil
      case checkpointManagerWindow:
        checkpointManagerWindow = nil
      default:
        break
      }
    }
  }
}
