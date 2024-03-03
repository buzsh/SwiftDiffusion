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
  @Published var checkForUpdatesErrorMessage: String? = nil
  
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
    
    await MainActor.run { self.isCheckingForUpdate = true }
    
    do {
      let updateAvailable = try await checkForUpdates()
      await MainActor.run {
        self.isCheckingForUpdate = false
        if updateAvailable {
          Debug.log("updateAvailable!")
        }
        self.lastCheckedTimestamp = Date()
        self.saveSettings()
      }
    } catch {
      await MainActor.run {
        self.checkForUpdatesErrorMessage = error.localizedDescription
        self.isCheckingForUpdate = false
      }
    }
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
  
  func checkForUpdates() async throws -> Bool {
    guard let url = URL(string: "https://github.com/revblaze/ReleaseParsingTest/releases") else {
      Debug.log("Invalid URL")
      return false
    }
    
    do {
      let html = try await fetchReleasesPage(url: url)
      Debug.log("Fetched HTML successfully")
      
      let releases = parseReleases(from: html)
      if !releases.isEmpty {
        for release in releases {
          Debug.log("GitReleases\n > Title: \(release.releaseTitle)\n > Build Number: \(release.releaseBuildNumber)")
        }
        return true
      } else {
        Debug.log("No releases found or parsing failed")
        return false
      }
    } catch {
      Debug.log("Failed to fetch releases page or parse HTML: \(error)")
      return false
    }
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
  func fetchReleasesPage(url: URL) async throws -> String {
    let (data, _) = try await URLSession.shared.data(from: url)
    return String(decoding: data, as: UTF8.self)
  }
  
  func parseReleases(from html: String) -> [GitRelease] {
    let sections = html.components(separatedBy: "<section aria-labelledby=").dropFirst()
    var releases: [GitRelease] = []
    
    for section in sections {
      if let titleStartRange = section.range(of: "<h2"),
         let titleCloseTagRange = section.range(of: ">", range: titleStartRange.upperBound..<section.endIndex),
         let titleEndRange = section.range(of: "</h2>", range: titleCloseTagRange.upperBound..<section.endIndex) {
        let title = String(section[titleCloseTagRange.upperBound..<titleEndRange.lowerBound])
          .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let buildNumberStartRange = section.range(of: "<sup><code>b"),
           let buildNumberEndRange = section.range(of: "</code></sup>", range: buildNumberStartRange.upperBound..<section.endIndex),
           let buildNumber = Int(section[buildNumberStartRange.upperBound..<buildNumberEndRange.lowerBound].filter("0123456789".contains)) {
          let release = GitRelease(releaseTitle: title, releaseDate: "", releaseTag: "", releaseBuildNumber: buildNumber, releaseAssets: [:])
          releases.append(release)
        }
      }
    }
    
    return releases
  }
}
