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
  
  @Published var errorMessage: String?
  @Published var showError: Bool = false
  
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
  
  func refreshModels() {
    Task {
      do {
        if let _ = T.refreshEndpoint {
          try await AutomaticApiService.shared.refreshData(for: T.self)
        }
      } catch {
        DispatchQueue.main.async {
          self.errorMessage = "Failed to refresh models: \(error.localizedDescription)"
          Debug.log(self.errorMessage)
          self.showError = true
        }
      }
    }
  }
  
  func loadModels() {
    Task {
      do {
        if let _ = T.refreshEndpoint {
          try await AutomaticApiService.shared.refreshData(for: T.self)
        }
        
        let models = try await AutomaticApiService.shared.fetchData(for: [T].self)
        DispatchQueue.main.async {
          self.models = models
          self.showError = false
        }
      } catch {
        DispatchQueue.main.async {
          self.errorMessage = "Failed to load models: \(error.localizedDescription)"
          Debug.log(self.errorMessage)
          self.showError = true
        }
      }
    }
  }
}


// Boilerplate code for SwiftUI:
/*
.alert("Error", isPresented: $modelManager.errorMessage.isNotNil()) {
    Button("OK", role: .cancel) { }
  }
message: {
  if let errorMessage = modelManager.errorMessage {
    Text(errorMessage)
  }
}

if modelManager.showError {
  Button("Retry") {
    modelManager.loadModels()
  }
}
*/
