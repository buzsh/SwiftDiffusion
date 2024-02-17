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
  private var scriptManager = ScriptManager.shared
  
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
  
  func loadInitialModels() {
    Task {
      do {
        let loras = try await LoraService.fetchLoras()
        await MainActor.run {
          self.loraModels = loras
        }
      } catch {
        await MainActor.run {
          Debug.log("Error fetching Loras: \(error.localizedDescription)")
        }
      }
    }
  }
}


class LoraService {
  static func fetchLoras() async throws -> [LoraModel] {
    let data = try await AutomaticApiService.shared.request(endpoint: Constants.API.Endpoint.getLoras)
    return try JSONDecoder().decode([LoraModel].self, from: data)
  }
  
  static func refreshLoras() async throws {
      try _ = await AutomaticApiService.shared.request(endpoint: Constants.API.Endpoint.postRefreshLoras, httpMethod: "POST")
  }
}
