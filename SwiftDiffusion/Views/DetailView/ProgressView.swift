//
//  ProgressView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI

class ProgressViewModel: ObservableObject {
  @Published var progress: Double = 0 {
    didSet {
      Debug.log("Progress updated to \(progress)")
    }
  }
}

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
  
  
  // Example method to demonstrate how you might call parseAndUpdateProgress
  func updateProgressBasedOnOutput(output: String) {
    Task {
      parseAndUpdateProgress(output: output)
    }
  }
}
