//
//  GitHubReleaseFetcher.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/3/24.
//

import Foundation

struct GitHubRelease {
  var releaseTitle: String?
  var releaseDate: String?
  var releaseTag: String?
  var releaseBuildNumber: Int?
  var releaseDownloadUrlString: String?
}

class GitHubReleaseFetcher {
  let urlString: String
  
  init(urlString: String) {
    self.urlString = urlString
  }
  
  func fetchReleasesPage() async throws -> String {
    guard let url = URL(string: urlString) else {
      throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    return String(decoding: data, as: UTF8.self)
  }
  
  func checkForUpdates() async throws -> [GitHubRelease] {
    let html = try await fetchReleasesPage()
    return parseReleases(from: html)
  }
  
  func fetchReleasesPage(url: URL) async throws -> String {
    let (data, _) = try await URLSession.shared.data(from: url)
    return String(decoding: data, as: UTF8.self)
  }
  
  func parseReleases(from html: String) -> [GitHubRelease] {
    let sections = html.components(separatedBy: "<section aria-labelledby=").dropFirst()
    var releases: [GitHubRelease] = []
    
    for section in sections {
      let title = extractTitle(from: section)
      let buildNumber = extractBuildNumber(from: section)
      let releaseDate = extractReleaseDate(from: section)
      let releaseTag = extractReleaseTag(from: section)
      let releaseDownloadUrlString = extractReleaseDownloadUrl(from: section)
      
      if let title = title, let buildNumber = buildNumber {
        let release = GitHubRelease(releaseTitle: title,
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
