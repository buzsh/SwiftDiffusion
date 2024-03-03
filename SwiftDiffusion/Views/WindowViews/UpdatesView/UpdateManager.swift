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
          Debug.log("GitReleases\n > Title: \(String(describing: release.releaseTitle))\n > Build Number: \(String(describing: release.releaseBuildNumber))\n > Release Date: \(String(describing: release.releaseDate))\n > Release Tag: \(String(describing: release.releaseTag))\n > Download URL: \(String(describing: release.releaseDownloadUrlString))")
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
  var releaseTitle: String?
  var releaseDate: String?
  var releaseTag: String?
  var releaseBuildNumber: Int?
  var releaseDownloadUrlString: String?
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
      let title = extractTitle(from: section)
      let buildNumber = extractBuildNumber(from: section)
      let releaseDate = extractReleaseDate(from: section)
      let releaseTag = extractReleaseTag(from: section)
      let releaseDownloadUrlString = extractReleaseDownloadUrl(from: section)
      
      if let title = title, let buildNumber = buildNumber {
        let release = GitRelease(releaseTitle: title,
                                 releaseDate: releaseDate,
                                 releaseTag: releaseTag,
                                 releaseBuildNumber: buildNumber,
                                 releaseDownloadUrlString: releaseDownloadUrlString)
        releases.append(release)
      }
    }
    
    return releases
  }
  
  
  
  func extractTitle(from section: String) -> String? {
    guard let titleStartRange = section.range(of: "<h2"),
          let titleCloseTagRange = section.range(of: ">", range: titleStartRange.upperBound..<section.endIndex),
          let titleEndRange = section.range(of: "</h2>", range: titleCloseTagRange.upperBound..<section.endIndex) else {
      return nil
    }
    return String(section[titleCloseTagRange.upperBound..<titleEndRange.lowerBound])
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  func extractBuildNumber(from section: String) -> Int? {
    guard let buildNumberStartRange = section.range(of: "<sup><code>b"),
          let buildNumberEndRange = section.range(of: "</code></sup>", range: buildNumberStartRange.upperBound..<section.endIndex) else {
      return nil
    }
    return Int(section[buildNumberStartRange.upperBound..<buildNumberEndRange.lowerBound].filter("0123456789".contains))
  }
  
  func extractReleaseDate(from section: String) -> String? {
    
    guard let dateStartRange = section.range(of: "<relative-time class=\"no-wrap\" prefix=\"\" datetime=\"") else {
      Debug.log("No <relative-time> tag found in section.")
      return nil
    }
    
    let dateStartIndex = section.index(dateStartRange.upperBound, offsetBy: 0)
    if let dateEndIndex = section[dateStartIndex...].firstIndex(of: "\"") {
      let date = section[dateStartIndex..<dateEndIndex]
      Debug.log("Extracted release date: \(date)")
      return String(date)
    } else {
      Debug.log("No closing quote for datetime attribute found.")
    }
    
    return nil
  }
  
  
  func extractReleaseTag(from section: String) -> String? {
    let pattern = #"<svg[^>]+octicon-tag[^>]+></svg>\s*<span[^>]*>\s*([^<]+)</span>"#
    
    do {
      let regex = try NSRegularExpression(pattern: pattern, options: [])
      let nsRange = NSRange(section.startIndex..<section.endIndex, in: section)
      
      if let match = regex.firstMatch(in: section, options: [], range: nsRange) {
        if let tagRange = Range(match.range(at: 1), in: section) {
          let tag = String(section[tagRange])
          Debug.log("Extracted release tag: \(tag)")
          return tag
        }
      }
    } catch {
      Debug.log("Regex error: \(error)")
    }
    
    Debug.log("Failed to extract release tag.")
    return nil
  }
  
  func extractReleaseDownloadUrl(from section: String) -> String? {
    let pattern = #"<a href=\"([^\"]+/releases/download/[^\"]+)\".*?>Download SwiftDiffusion.app</a>"#
    
    do {
      let regex = try NSRegularExpression(pattern: pattern, options: [])
      let nsRange = NSRange(section.startIndex..<section.endIndex, in: section)
      
      if let match = regex.firstMatch(in: section, options: [], range: nsRange) {
        if let urlRange = Range(match.range(at: 1), in: section) {
          let urlString = String(section[urlRange])
          Debug.log("Extracted download URL: \(urlString)")
          return urlString
        }
      }
    } catch {
      Debug.log("Regex error: \(error)")
    }
    
    Debug.log("Failed to extract download URL.")
    return nil
  }
  
}
