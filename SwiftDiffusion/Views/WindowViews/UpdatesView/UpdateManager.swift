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
  @Published var githubReleases: [GitHubRelease] = []
  @Published var latestRelease: GitHubRelease? = nil
  
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
          Debug.log("Update Available!")
          if let release = latestRelease {
            Debug.log("latestRelease: GitRelease =\n > Title: \(String(describing: release.releaseTitle))\n > Build Number: \(String(describing: release.releaseBuildNumber))\n > Release Date: \(String(describing: release.releaseDate))\n > Release Tag: \(String(describing: release.releaseTag))\n > Download URL: \(String(describing: release.releaseDownloadUrlString))")
          } else {
            Debug.log("latestRelease: GitRelease = nil")
          }
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
    let fetcher = GitHubReleaseFetcher(urlString: "https://github.com/revblaze/ReleaseParsingTest/releases")
    let releases = try await fetcher.checkForUpdates()
    
    if !releases.isEmpty {
      githubReleases = releases
      
      for release in githubReleases {
        Debug.log("GitReleases\n > Title: \(String(describing: release.releaseTitle))\n > Build Number: \(String(describing: release.releaseBuildNumber))\n > Release Date: \(String(describing: release.releaseDate))\n > Release Tag: \(String(describing: release.releaseTag))\n > Download URL: \(String(describing: release.releaseDownloadUrlString))")
      }
      
      return compareCurrentAppBuildToGitHubReleases()
    } else {
      return false
    }
  }
  
  func compareCurrentAppBuildToGitHubReleases() -> Bool {
    guard let highestBuildRelease = githubReleases
      .filter({ $0.releaseBuildNumber ?? 0 > AppInfo.buildInt })
      .max(by: { ($0.releaseBuildNumber ?? 0) < ($1.releaseBuildNumber ?? 0) }) else {
      return false
    }
    
    latestRelease = highestBuildRelease
    return true
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
