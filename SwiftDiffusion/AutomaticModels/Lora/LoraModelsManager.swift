//
//  LoraModelsManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

class LoraModelsManager: ObservableObject {
  @Published var loraModels: [LoraModel] = []
  private var directoryObserver: DirectoryObserver?
  private var userSettings = UserSettings.shared
  
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
        try await AutomaticApiService.shared.refreshData(for: LoraModel.self)
        
        let models = try await AutomaticApiService.shared.fetchData(for: [LoraModel].self)
        DispatchQueue.main.async {
          self.loraModels = models
        }
      } catch {
        // Handle or log error appropriately
        Debug.log("Error in refreshing or fetching Loras: \(error.localizedDescription)")
      }
    }
  }
  
  func refreshLoras() {
    Task {
      do {
        try await AutomaticApiService.shared.refreshData(for: LoraModel.self)
        self.loadInitialModels()
      } catch {
        Debug.log("Error refreshing Loras: \(error.localizedDescription)")
      }
    }
  }
}
