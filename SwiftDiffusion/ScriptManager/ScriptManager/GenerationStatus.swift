//
//  GenerationStatus.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation

enum GenerationStatus {
  case idle
  case preparingToGenerate
  case generating
  case finishingUp
  case done
}

/*
 >>
  12%|█▎        | 1/8 [00:01<00:12,  1.80s/it]
 */

extension ScriptManager {
  func parseAndUpdateProgress(output: String) {
    let regexPattern = "\\s*(Total progress: )?(\\d+)%"
    do {
      let regex = try NSRegularExpression(pattern: regexPattern, options: [])
      let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
      let matches = regex.matches(in: output, options: [], range: nsRange)
      
      for match in matches {
        let matchRange = match.range(at: 2) // Assuming group 2 captures the percentage
        if matchRange.length > 0, let range = Range(matchRange, in: output) {
          let progressString = String(output[range])
          if let progressValue = Double(progressString) {
            DispatchQueue.main.async {
              self.progressHasReachedAboveZero(progressValue)
              self.genProgress = progressValue / 100.0
              Debug.log("Updated progress to \(progressValue)%")
            }
            break // Optionally break after the first successful update
          }
        }
      }
    } catch {
      Debug.log("Regex error: \(error)")
    }
  }
  
  func progressHasReachedAboveZero(_ progress: Double) {
    if progress > 0 {
      genStatus = .generating
    }
    
    if progress >= 100 {
      genStatus = .finishingUp
    }
  }
  
  func updateProgressBasedOnOutput(output: String) {
    Task {
      parseAndUpdateProgress(output: output)
    }
  }
}
