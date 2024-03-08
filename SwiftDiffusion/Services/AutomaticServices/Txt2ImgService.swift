//
//  Txt2ImgService.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

class Txt2ImgService {
  static let shared = Txt2ImgService()
  
  private init() {}
  
  func sendImageGenerationRequest(to endpoint: Constants.API.Endpoint, with payload: [String: Any], baseAPI: URL) async -> [String]? {
    guard let url = endpoint.url(relativeTo: baseAPI) else {
      Debug.log("[Txt2ImgService] Invalid URL for endpoint: \(endpoint)")
      return nil
    }
    
    do {
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
      
      let session = URLSession(configuration: self.customSessionConfiguration())
      let (data, _) = try await session.data(for: request)
      
      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
         let images = json["images"] as? [String] {
        return images
      }
    } catch {
      Debug.log("[Txt2ImgService] API request failed with error: \(error)")
    }
    return nil
  }
  
  private func customSessionConfiguration() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = Constants.API.timeoutInterval
    configuration.timeoutIntervalForResource = Constants.API.timeoutInterval
    return configuration
  }
}
