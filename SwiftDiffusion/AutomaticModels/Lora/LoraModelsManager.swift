//
//  LoraModelsManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

/* Boilerplat code:
func someFunction() async {
  do {
    try await LoraService.refreshLoras()
    // Proceed with refreshed data
  } catch {
    // Handle errors (e.g., network issues, decoding failures)
    print("Failed to refresh Loras: \(error)")
  }
}
 */

extension Constants.API.Endpoint {
  static let getLoras = "/sdapi/v1/loras"
  static let postRefreshLoras = "/sdapi/v1/refresh-loras"
}

class LoraModelsManager: ObservableObject {
  @Published var loraModels: [LoraModel] = []
  private var directoryObserver: DirectoryObserver?
  private var userSettings = UserSettings.shared
  private let scriptManager = ScriptManager.shared
  
  func startObservingLoraDirectory() {
    guard let loraDirectoryUrl = userSettings.loraDirectoryUrl else { return }
    
    loadInitialModels()
    
    directoryObserver = DirectoryObserver()
    directoryObserver?.startObserving(url: loraDirectoryUrl) { [weak self] in
      DispatchQueue.main.async {
        self?.loadInitialModels()
      }
    }
  }
  
  func stopObservingLoraDirectory() {
    directoryObserver?.stopObserving()
  }
}

extension LoraModelsManager {
  func loadInitialModels() {
    Task {
      do {
        let loras = try await LoraService.fetchLoras()
        DispatchQueue.main.async {
          self.loraModels = loras
        }
      } catch {
        Debug.log("Error fetching Loras: \(error.localizedDescription)")
      }
    }
  }
}

class LoraService {
  static func fetchLoras() async throws -> [LoraModel] {
    let data = try await AutomaticApiService.shared.request(endpoint: Constants.API.Endpoint.getLoras)
    let loras = try JSONDecoder().decode([LoraModel].self, from: data)
    return loras
  }
  
  static func refreshLoras() async throws {
    _ = try await AutomaticApiService.shared.request(endpoint: Constants.API.Endpoint.postRefreshLoras, httpMethod: "POST")
  }
}

extension LoraModelsManager {
  func getLorasFromApi() async {
    guard await postRefreshLoras() else {
      Debug.log("[LoraModelsManager] Failed to refresh LoRAs. Aborting fetch.")
      return
    }
    
    guard let data = await performAPIRequest(to: Constants.API.Endpoint.getLoras) else {
      return
    }
    
    do {
      let loras = try JSONDecoder().decode([LoraModel].self, from: data)
      await MainActor.run {
        let currentPaths = Set(self.loraModels.map { $0.path })
        let uniqueLoras = loras.filter { !currentPaths.contains($0.path) }
        self.loraModels.append(contentsOf: uniqueLoras)
      }
    } catch {
      Debug.log("Failed to parse Lora models: \(error.localizedDescription)")
    }
  }
  
  func postRefreshLoras() async -> Bool {
    return await performAPIRequest(to: Constants.API.Endpoint.postRefreshLoras, httpMethod: "POST") != nil
  }
}


extension LoraModelsManager {
  private func performAPIRequest(to endpoint: String, httpMethod: String = "GET") async -> Data? {
    guard let apiUrl = await scriptManager.serviceUrl,
          let url = URL(string: apiUrl.appendingPathComponent(endpoint).absoluteString) else {
      Debug.log("Invalid API URL or Endpoint.")
      return nil
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = httpMethod
    
    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
        Debug.log("API request failed with response: \(response)")
        return nil
      }
      return data
    } catch {
      Debug.log("API request failed: \(error.localizedDescription)")
      return nil
    }
  }
}
