//
//  CheckpointsApiManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import Foundation
import Combine

class CheckpointsApiManager: ObservableObject {
  @Published var checkpoints: [CheckpointModel] = []
  @Published var loadedCheckpoint: String? = nil
  private let baseURL: String
  
  init(baseURL: String) {
    self.baseURL = baseURL
  }
  
  /// Tells Automatic1111 to refresh the list of available model checkpoints by sending a POST request to the server.
  /// Throws an error if the URL is invalid or the server responds with an error.
  func refreshCheckpointsAsync() async throws {
    guard let url = URL(string: "\(baseURL)/sdapi/v1/refresh-checkpoints") else {
      throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "accept")
    
    let (_, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
  }
  
  /// Retrieves the list of available model checkpoints from the Automatic1111 server by sending a GET request.
  /// Updates the `checkpoints` published property with the response.
  /// Throws an error if the URL is invalid, the server responds with an error, or the response cannot be decoded.
  func getCheckpointsAsync() async throws {
    guard let url = URL(string: "\(baseURL)/sdapi/v1/sd-models") else {
      throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue("application/json", forHTTPHeaderField: "accept")
    
    let (data, httpResponse) = try await URLSession.shared.data(for: request)
    guard (httpResponse as? HTTPURLResponse)?.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    let decoder = JSONDecoder()
    let decodedResponse = try decoder.decode([CheckpointApiModel].self, from: data)
    self.checkpoints = decodedResponse.map { CheckpointModel(name: $0.title, path: $0.filename, type: .python, checkpointApiModel: $0) }
  }
  
  /// Fetches the currently loaded checkpoint configuration, loaded into memory, from the Automatic1111 server by sending a GET request.
  /// Updates the `loadedCheckpoint` published property with the checkpoint's title (JSON key `sd_model_checkpoint`).
  /// Throws an error if the URL is invalid, the server responds with an error, or the response cannot be decoded.
  func getLoadedCheckpointAsync() async throws {
    guard let url = URL(string: "\(baseURL)/sdapi/v1/options") else {
      throw URLError(.badURL)
    }
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
  
  /// Posts a request to load a specific model checkpoint into memory by sending a POST request with the checkpoint's title (JSON key `sd_model_checkpoint`).
  /// Throws an error if the URL is invalid, the server responds with an error, or the request cannot be encoded.
  /// - Parameter checkpoint: The name of the checkpoint to be loaded.
  func postLoadCheckpointAsync(checkpoint: String) async throws {
    guard let url = URL(string: "\(baseURL)/sdapi/v1/options") else {
      throw URLError(.badURL)
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "accept")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ClientConfig(sdModelCheckpoint: checkpoint)
    let encoder = JSONEncoder()
    do {
      let jsonData = try encoder.encode(body)
      request.httpBody = jsonData
    } catch {
      throw URLError(.cannotParseResponse)
    }
    
    let (_, httpResponse) = try await URLSession.shared.data(for: request)
    
    guard let response = httpResponse as? HTTPURLResponse, response.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
  }
  
}
