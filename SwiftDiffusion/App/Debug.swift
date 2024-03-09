//
//  Debug.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

let CanvasPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

/// A debugging utility class that conditionally performs logging and actions based on its active state.
///
/// This class provides a global access point through `Debug.shared` to perform logging and execute closures conditionally if debugging is enabled.
class Debug: ObservableObject {
  /// The singleton instance for global access.
  static let shared = Debug()
  
  /// Indicates whether debugging actions should be performed.
  @Published var isActive = true
  
  /// Logs a given value to the console if debugging is active.
  ///
  /// Use this instance method to log any value (e.g., String, Int) when debugging is enabled.
  ///
  /// - Parameter value: The value to be logged.
  ///
  /// **Usage:**
  ///
  /// ```swift
  /// Debug.shared.logInstance("Debugging started")
  /// ```
  ///
  /// - important: Use `Debug.log` instead.
  private func logInstance<T>(_ value: T) {
    if isActive {
      print(value)
    }
  }
  
  /// Logs a given value to the console if debugging is active.
  ///
  /// Use this static method to log any value conveniently without needing direct access to the `Debug` singleton.
  ///
  /// - Parameter value: The value to be logged.
  ///
  /// **Usage:**
  ///
  /// ```swift
  /// Debug.log("User login attempt")
  /// ```
  static func log<T>(_ value: T) {
    Debug.shared.logInstance(value)
  }
  /// Executes a closure if debugging is active.
  ///
  /// This instance method conditionally performs the given action allowing for execution of debugging-specific tasks.
  ///
  /// - Parameter action: A closure to be executed if debugging is active.
  ///
  /// **Usage:**
  ///
  /// ```swift
  /// Debug.shared.perform {
  ///   print("Performing an action specific to debugging.")
  /// }
  /// ```
  ///
  /// - important: Use `Debug.perform` instead
  private func perform(action: () -> Void) {
    if isActive {
      action()
    }
  }
  
  /// Executes a closure if debugging is active.
  ///
  /// This static method provides a convenient way to execute debugging-specific tasks without needing direct access to the `Debug` singleton.
  ///
  /// - Parameter action: A closure to be executed if debugging is active.
  ///
  /// **Usage:**
  ///
  /// ```swift
  /// Debug.perform {
  ///   print("Performing an action specific to debugging.")
  /// }
  /// ```
  static func perform(action: @escaping () -> Void) {
    Debug.shared.perform(action: action)
  }
}
