//
//  ApiManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import Foundation
import Combine

class APIManager: ObservableObject {
  @Published var checkpoints: [Checkpoint] = []
  @Published var loadedCheckpoint: String? = nil
  private let baseURL: String
  
  init(baseURL: String) {
    self.baseURL = baseURL
  }
  
  func refreshCheckpointsAsync() async throws {
    let url = URL(string: "\(baseURL)/sdapi/v1/refresh-checkpoints")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "accept")
    
    let (_, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
  }
  
  func getCheckpointsAsync() async throws {
    let url = URL(string: "\(baseURL)/sdapi/v1/sd-models")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "accept")
    
    let (data, httpResponse) = try await URLSession.shared.data(for: request)
    guard (httpResponse as? HTTPURLResponse)?.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    let decoder = JSONDecoder()
    let decodedResponse = try decoder.decode([CheckpointApiModel].self, from: data)
    self.checkpoints = decodedResponse.map { Checkpoint(name: $0.title, path: $0.filename, checkpointApiModel: $0) }
  }
  
  func getLoadedCheckpointAsync() async throws {
    let url = URL(string: "\(baseURL)/sdapi/v1/options")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "accept")
    
    let (data, httpResponse) = try await URLSession.shared.data(for: request)
    guard (httpResponse as? HTTPURLResponse)?.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    let decoder = JSONDecoder()
    let decodedResponse = try decoder.decode(ClientConfig.self, from: data)
    self.loadedCheckpoint = decodedResponse.sdModelCheckpoint
  }
  
}
