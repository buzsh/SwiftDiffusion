//
//  GenerationStatus.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation

extension ScriptManager {
  // Assuming this is your existing init or somewhere you can access ProgressViewModel
  func parseAndUpdateProgress(output: String) {
    let regexPattern = "Total progress: *(\\d+)%|^(\\d+)%"
    
    do {
      let regex = try NSRegularExpression(pattern: regexPattern, options: [])
      let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
      let matches = regex.matches(in: output, options: [], range: nsRange)
      
      for match in matches {
        let matchRange1 = match.range(at: 1)
        let matchRange2 = match.range(at: 2)
        
        if matchRange1.length > 0, let range1 = Range(matchRange1, in: output) {
          let progressString = String(output[range1])
          if let progressValue = Double(progressString) {
            DispatchQueue.main.async {
              self.progressHasReachedAboveZero(progressValue)
              self.genProgress = progressValue / 100.0
              Debug.log("Updated progress to \(progressValue)%")
            }
          }
        } else if matchRange2.length > 0, let range2 = Range(matchRange2, in: output) {
          let progressString = String(output[range2])
          if let progressValue = Double(progressString) {
            DispatchQueue.main.async {
              self.progressHasReachedAboveZero(progressValue)
              self.genProgress = progressValue / 100.0
              Debug.log("Updated progress to \(progressValue)%")
            }
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
