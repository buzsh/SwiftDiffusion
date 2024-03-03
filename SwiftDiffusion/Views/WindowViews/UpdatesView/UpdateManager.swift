//
//  UpdateManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/3/24.
//

import Foundation
import SwiftUI

enum UpdateFrequency: String, CaseIterable {
  case everyAppLaunch = "Every App Launch"
  case daily = "Daily"
  case weekly = "Weekly"
  case everyOtherWeek = "Every Other Week"
  case monthly = "Monthly"
}


class UpdateManager: ObservableObject {
  @Published var lastCheckedTimestamp: Date?
  @Published var isCheckingForUpdate: Bool = false
  private var updateCheckFrequency: UpdateFrequency = .everyAppLaunch // Default value, load this from user preferences
  
  init() {
    // Initialize from saved settings, if available
    loadSettings()
  }
  
  func loadSettings() {
    // Load your saved frequency and last checked timestamp here
    // For demonstration, using UserDefaults (not recommended for production)
    if let frequencyRawValue = UserDefaults.standard.string(forKey: "updateCheckFrequency"),
       let frequency = UpdateFrequency(rawValue: frequencyRawValue) {
      updateCheckFrequency = frequency
    }
    lastCheckedTimestamp = UserDefaults.standard.object(forKey: "lastCheckedTimestamp") as? Date
  }
  
  func saveSettings() {
    // Save your frequency and last checked timestamp here
    UserDefaults.standard.set(updateCheckFrequency.rawValue, forKey: "updateCheckFrequency")
    UserDefaults.standard.set(lastCheckedTimestamp, forKey: "lastCheckedTimestamp")
  }
  
  func checkForUpdatesIfNeeded() async {
    guard shouldCheckForUpdates() else { return }
    
    isCheckingForUpdate = true // Indicate that checking for updates has started
    let updateAvailable = await checkForUpdates()
    isCheckingForUpdate = false // Reset the flag after checking
    
    if updateAvailable {
      // If true, there is an update available. Open the UpdatesView with download button.
      // This part will depend on your app's architecture.
      // You might post a notification, use a state manager, etc., to switch the view.
    }
    
    // Update the last checked timestamp regardless of update availability
    lastCheckedTimestamp = Date()
    saveSettings()
  }
  
  private func shouldCheckForUpdates() -> Bool {
    guard let lastChecked = lastCheckedTimestamp else { return true }
    
    let calendar = Calendar.current
    let now = Date()
    
    switch updateCheckFrequency {
    case .everyAppLaunch:
      return true
    case .daily:
      return calendar.isDate(lastChecked, inSameDayAs: now) == false
    case .weekly:
      return !calendar.isDate(lastChecked, equalTo: now, toGranularity: .weekOfYear)
    case .everyOtherWeek:
      if let nextCheckDate = calendar.date(byAdding: .weekOfYear, value: 2, to: lastChecked) {
        return nextCheckDate <= now
      }
      return false
    case .monthly:
      return !calendar.isDate(lastChecked, equalTo: now, toGranularity: .month)
    }
  }
  
  private func checkForUpdates() async -> Bool {
    // Here, you would check for updates. This is a placeholder for your update logic.
    // Return true if an update is available, false otherwise.
    return false // Placeholder return value
  }
}
