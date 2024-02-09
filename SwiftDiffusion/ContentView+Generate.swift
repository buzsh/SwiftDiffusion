//
//  ContentView+Generate.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI
import Combine

extension ContentView {
  func generatePayload() -> [String: Any] {
    // Collect values from PromptViewModel
    let prompt = promptViewModel.positivePrompt
    let negativePrompt = promptViewModel.negativePrompt
    let width = Int(promptViewModel.width)
    let height = Int(promptViewModel.height)
    let cfgScale = promptViewModel.cfgScale
    let steps = Int(promptViewModel.samplingSteps)
    let seed = Int(promptViewModel.seed) ?? -1 // Assuming seed is a string that can be converted to Int
    let batchCount = Int(promptViewModel.batchCount)
    let batchSize = Int(promptViewModel.batchSize)
    let model = promptViewModel.selectedModel?.name ?? ""
    let samplingMethod = promptViewModel.samplingMethod ?? ""
    
    // Construct the JSON payload
    let jsonPayload: [String: Any] = [
      "alwayson_scripts": [
        "API payload": ["args": []],
        "AnimateDiff": [
          "args": [
            [
              "batch_size": batchSize,
              "model": model,
              "request_id": "",
              // Add other values as needed
            ]
          ]
        ],
        // Add other scripts as needed
      ],
      "batch_size": batchCount,
      "cfg_scale": cfgScale,
      "height": height,
      "negative_prompt": negativePrompt,
      "prompt": prompt,
      "sampler_name": samplingMethod,
      "seed": seed,
      "steps": steps,
      "width": width,
      // Add other fields as needed
    ]
    
    return jsonPayload
    
    // Convert JSON payload to Data
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: jsonPayload, options: .prettyPrinted)
      // Here, you can either convert jsonData to a String and print it,
      // or use it directly as the body of a network request.
      let jsonString = String(data: jsonData, encoding: .utf8)
      Debug.log(jsonString ?? "Invalid JSON")
    } catch {
      Debug.log("Error creating JSON: \(error.localizedDescription)")
    }
  }
}

extension ContentView {
  func prepareAndSendAPIRequest() async {
    guard scriptManager.scriptState == .active, let baseUrl = scriptManager.serviceUrl else {
      Debug.log("Script is not active or URL is unavailable")
      return
    }
    
    let overrideSettings: [String: Any] = [
        "CLIP_stop_at_last_layers": Int(promptViewModel.clipSkip),
        // Include other override settings as needed, for example:
        "filter_nsfw": false  // or any other setting you wish to override
    ]
    
    let payload: [String: Any] = [
      "prompt": promptViewModel.positivePrompt,
      "negative_prompt": promptViewModel.negativePrompt,
      "width": Int(promptViewModel.width),
      "height": Int(promptViewModel.height),
      "cfg_scale": Int(promptViewModel.cfgScale),
      "steps": Int(promptViewModel.samplingSteps),
      "seed": Int(promptViewModel.seed) ?? -1, // Assuming seed is a string that can be converted to Int
      "batch_count": Int(promptViewModel.batchCount),
      "batch_size": Int(promptViewModel.batchSize),
      "override_settings": overrideSettings,
      // Include other necessary fields as per your API's requirements
      "do_not_save_grid" : false,
      "do_not_save_samples" : false
    ]
    
    Debug.log("Sending API request to \(baseUrl)\n > \(payload)")
    
    await sendAPIRequest(api: baseUrl, payload: payload)
  }
}

extension ContentView {
  func sendAPIRequest(api: URL, payload: [String: Any]) async {
    Debug.log("API base URL: \(api)")
    
    let endpoint = "sdapi/v1/txt2img"
    guard let url = URL(string: endpoint, relativeTo: api) else {
      Debug.log("Invalid URL")
      return
    }
    
    do {
      let requestData = try JSONSerialization.data(withJSONObject: payload, options: [])
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = requestData
      
      let (data, _) = try await URLSession.shared.data(for: request)
      
      // Parse the JSON response
      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
         let images = json["images"] as? [String], !images.isEmpty,
         let imageData = Data(base64Encoded: images[0]) {
        Task { @MainActor in  // Use Task to switch to the Main Actor
          if let nsImage = NSImage(data: imageData) {
            await MainActor.run {
              self.selectedImage = nsImage
            }
          }
        }
      }
    } catch {
      Task { @MainActor in  // Use Task for error handling on the Main Actor
        Debug.log("Request error: \(error)")
      }
    }
  }
}
