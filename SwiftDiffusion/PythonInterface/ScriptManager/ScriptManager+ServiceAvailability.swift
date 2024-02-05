//
//  ScriptManager+ServiceAvailability.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

extension ScriptManager {
  
  func checkScriptServiceAvailability(completion: @escaping (Bool) -> Void) {
    guard let url = serviceURL else {
      Debug.log("Service URL not available.")
      completion(false)
      return
    }
    
    let task = URLSession.shared.dataTask(with: url) { _, response, error in
      DispatchQueue.main.async {
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
          // page loaded successfully, script is likely still running
          completion(true)
        } else {
          // request failed, script is likely terminated
          completion(false)
        }
      }
    }
    
    task.resume()
  }
}
