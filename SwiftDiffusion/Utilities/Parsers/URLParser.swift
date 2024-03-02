//
//  URLParser.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/2/24.
//

import Foundation

class URLParser {
  struct URLParsingConfig {
    let pattern: String
    let messageContains: String
  }
  
  func parseURL(from output: String, withConfigs configs: [URLParsingConfig], completion: @escaping (URL?) -> Void) {
    for config in configs {
      if let urlStr = extractURL(from: output, using: config), let url = URL(string: urlStr) {
        DispatchQueue.main.async {
          completion(url)
        }
        return
      }
    }
    DispatchQueue.main.async {
      completion(nil)
    }
  }
  
  private func extractURL(from output: String, using config: URLParsingConfig) -> String? {
    guard output.contains(config.messageContains) else { return nil }
    
    do {
      let regex = try NSRegularExpression(pattern: config.pattern, options: .caseInsensitive)
      let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
      if let match = regex.firstMatch(in: output, options: [], range: nsRange),
         let urlRange = Range(match.range(at: 1), in: output) {
        return String(output[urlRange])
      }
    } catch {
      Debug.log("[URLParser.extractURL] Regex error: \(error)")
    }
    
    return nil
  }
}
