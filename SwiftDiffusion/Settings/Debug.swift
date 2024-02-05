//
//  Debug.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

class Debug: ObservableObject {
  static let shared = Debug()
  @Published var isActive = true
  
  // Instance method for logging
  private func logInstance<T>(_ value: T) {
    if isActive {
      print(value)
    }
  }
  
  // Static method interface for logging
  static func log<T>(_ value: T) {
    Debug.shared.logInstance(value)
  }
  
  // Instance method to conditionally perform an action
  private func perform(action: () -> Void) {
    if isActive {
      action()
    }
  }
  
  // Static method interface to conditionally perform an action
  static func perform(action: @escaping () -> Void) {
    Debug.shared.perform(action: action)
  }
}
