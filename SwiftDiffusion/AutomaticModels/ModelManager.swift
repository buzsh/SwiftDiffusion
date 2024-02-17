//
//  ModelManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

class ModelManager<T: Decodable & EndpointRepresentable>: ObservableObject {
  @Published var models: [T] = []
  private var directoryObserver: DirectoryObserver?
  private var userSettings = UserSettings.shared
  
  func startObservingDirectory() {
    guard let directoryUrl = UserSettings.shared.modelDirectoryUrl(forType: T.self) else { return }
    
    loadModels()
    
    directoryObserver = DirectoryObserver()
    directoryObserver?.startObserving(url: directoryUrl) { [weak self] in
      DispatchQueue.main.async {
        self?.loadModels()
      }
    }
  }
  
  func stopObservingDirectory() {
    directoryObserver?.stopObserving()
  }
  
  func loadModels() {
    Task {
      do {
        let models = try await AutomaticApiService.shared.fetchData(for: [T].self)
        DispatchQueue.main.async {
          self.models = models
        }
      } catch {
        // Handle or log error appropriately
      }
    }
  }
}
