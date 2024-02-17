//
//  LoraModelsManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

extension Constants.API.Endpoint {
  static let getLoras = "/sdapi/v1/loras"
  static let postRefreshLoras = "/sdapi/v1/refresh-loras"
}

class LoraModelsManager: ObservableObject {
  @Published var loraModels: [LoraModel] = []
  private var directoryObserver: DirectoryObserver?
  private var userSettings = UserSettings.shared
  private let scriptManager = ScriptManager.shared

  
  func loadInitialModels() {
    Task {
      await getLorasFromApi()
    }
  }
  
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
  func getLorasFromApi() async {
    
    guard await postRefreshLoras() else {
      Debug.log("[LoraModelsManager] Failed to refresh LoRAs. Aborting fetch.")
      return
    }
    
    guard let apiUrl = await scriptManager.serviceUrl else {
      Debug.log("Service URL is nil.")
      return
    }
    
    let endpoint = apiUrl.appendingPathComponent(Constants.API.Endpoint.getLoras)
    do {
      let (data, _) = try await URLSession.shared.data(from: endpoint)
      let decoder = JSONDecoder()
      let loras = try decoder.decode([LoraModel].self, from: data)
      
      await MainActor.run {
        let currentPaths = Set(self.loraModels.map { $0.path })
        let uniqueLoras = loras.filter { !currentPaths.contains($0.path) }
        self.loraModels.append(contentsOf: uniqueLoras)
      }
    } catch {
      Debug.log("Failed to fetch or parse Lora models: \(error.localizedDescription)")
    }
  }
}

extension LoraModelsManager {
  func postRefreshLoras() async -> Bool {
    guard let apiUrl = await scriptManager.serviceUrl else {
      Debug.log("Service URL is nil.")
      return false
    }
    
    let endpoint = apiUrl.appendingPathComponent(Constants.API.Endpoint.postRefreshLoras)
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    
    do {
      let (_, response) = try await URLSession.shared.data(for: request)
      
      if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
        return true
      } else {
        Debug.log("Refresh Loras request failed with response: \(response)")
        return false
      }
    } catch {
      Debug.log("Failed to post refresh Loras: \(error.localizedDescription)")
      return false
    }
  }
}
