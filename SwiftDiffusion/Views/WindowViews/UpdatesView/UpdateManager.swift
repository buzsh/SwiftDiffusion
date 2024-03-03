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
  @Published var updateCheckFrequency: UpdateFrequency = .everyAppLaunch
  
  init() {
    loadSettings()
  }
  
  func loadSettings() {
    if let frequencyRawValue = UserDefaults.standard.string(forKey: "updateCheckFrequency"),
       let frequency = UpdateFrequency(rawValue: frequencyRawValue) {
      updateCheckFrequency = frequency
    }
    lastCheckedTimestamp = UserDefaults.standard.object(forKey: "lastCheckedTimestamp") as? Date
  }
  
  func saveSettings() {
    UserDefaults.standard.set(updateCheckFrequency.rawValue, forKey: "updateCheckFrequency")
    UserDefaults.standard.set(lastCheckedTimestamp, forKey: "lastCheckedTimestamp")
  }
  
  func checkForUpdatesIfNeeded(force: Bool = false) async {
    guard force || shouldCheckForUpdates() else { return }
    
    isCheckingForUpdate = true
    let updateAvailable = await checkForUpdates()
    isCheckingForUpdate = false
    
    if updateAvailable {
      Debug.log("updateAvailable!")
      // If true, there is an update available. Open the UpdatesView with download button.
      // This part will depend on your app's architecture.
      // You might post a notification, use a state manager, etc., to switch the view.
    }
    
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
  
  func checkForUpdates() async -> Bool {
    guard let url = URL(string: "https://github.com/revblaze/ReleaseParsingTest/releases") else {
      Debug.log("Invalid URL")
      return false
    }
    
    guard let html = await fetchReleasesPage(url: url) else {
      Debug.log("Failed to fetch releases page")
      return false
    }
    
    let releases = parseReleases(from: html)
    for release in releases {
      Debug.log("Title: \(release.releaseTitle), Build Number: \(release.releaseBuildNumber)")
    }
    
    // Placeholder logic to determine if an update is available
    // You would compare the fetched releases against the current app version and build number
    return !releases.isEmpty
  }
}

extension UpdateManager {
  var lastCheckedTimestampFormatted: String {
    if let lastChecked = lastCheckedTimestamp {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .short
      return formatter.string(from: lastChecked)
    } else {
      return "Never"
    }
  }
}

struct GitRelease {
  var releaseTitle: String
  var releaseDate: String
  var releaseTag: String
  var releaseBuildNumber: Int
  var releaseAssets: [String: String]
}


extension UpdateManager {
  func fetchReleasesPage(url: URL) async -> String? {
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      return String(decoding: data, as: UTF8.self)
    } catch {
      Debug.log("Error fetching releases page: \(error)")
      return nil
    }
  }
  
  func parseReleases(from html: String) -> [GitRelease] {
    let sections = html.components(separatedBy: "<section aria-labelledby=")
    var releases: [GitRelease] = []
    
    for section in sections.dropFirst() {
      if let titleStartRange = section.range(of: ">"),
         let titleEndRange = section.range(of: "</h2>") {
        let title = String(section[titleStartRange.upperBound..<titleEndRange.lowerBound])
        
        if let buildNumberStartRange = section.range(of: "<sup><code>b"),
           let buildNumberEndRange = section.range(of: "</code></sup>", range: buildNumberStartRange.lowerBound..<section.endIndex) {
          let buildNumberString = String(section[buildNumberStartRange.upperBound..<buildNumberEndRange.lowerBound])
            .filter { "0"..."9" ~= $0 }
          
          if let buildNumber = Int(buildNumberString) {
            let release = GitRelease(releaseTitle: title, releaseDate: "", releaseTag: "", releaseBuildNumber: buildNumber, releaseAssets: [:])
            releases.append(release)
          }
        }
      }
    }
    
    return releases
  }
}
