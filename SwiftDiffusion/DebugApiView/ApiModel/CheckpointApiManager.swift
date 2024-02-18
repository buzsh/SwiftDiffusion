//
//  CheckpointApiManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import Foundation

class CheckpointsManager: ObservableObject {
  @Published var models: [Checkpoint] = []
  
  private var directoryObserver: DirectoryObserver?
  private var userSettings = UserSettings.shared
  
  @Published var errorMessage: String?
  @Published var showError: Bool = false
  
  let apiManager: APIManager
  
  init(apiManager: APIManager) {
    self.apiManager = apiManager
  }
  
  func startObservingDirectory() {
    guard let directoryUrl = UserSettings.shared.stableDiffusionModelsDirectoryUrl else { return }
    
    addLocalCheckpointsFromDirectoryToModels()
    
    directoryObserver = DirectoryObserver()
    directoryObserver?.startObserving(url: directoryUrl) { [weak self] in
      
      DispatchQueue.main.async {
        
        self?.addLocalCheckpointsFromDirectoryToModels()
        
        Task {
          await self?.updateCheckpointsFromAPI()
        }
        
      }
    }
  }
  
  func stopObservingDirectory() {
    directoryObserver?.stopObserving()
  }
  
}

extension CheckpointsManager {
  
  func updateCheckpointsFromAPI() async {
    Debug.log("Starting updateCheckpointsFromAPI")
    let result = await refreshAndAssignApiCheckpoints(apiManager: self.apiManager)
    switch result {
    case .success(let message):
      Debug.log(message)
      DispatchQueue.main.async {
        for apiCheckpoint in self.apiManager.checkpoints {
          if let existingCheckpoint = self.checkpointWithPathAlreadyExistsInModels(compare: apiCheckpoint) {
            existingCheckpoint.checkpointApiModel = apiCheckpoint.checkpointApiModel
          }
        }
      }
    case .failure(let error):
      DispatchQueue.main.async {
        self.errorMessage = "Failed to update checkpoints from API: \(error.localizedDescription)"
        self.showError = true
      }
      Debug.log(error.localizedDescription)
    }
  }
}


extension CheckpointsManager {
  func refreshAndAssignApiCheckpoints(apiManager: APIManager) async -> Result<String, Error> {
    Debug.log("refreshAndAssignApiCheckpoints")
    do {
      try await apiManager.refreshCheckpointsAsync()
      try await apiManager.getCheckpointsAsync()
      return .success("Success!")
    } catch {
      return .failure(error)
    }
  }
}

extension CheckpointsManager {
  func checkpointWithPathAlreadyExistsInModels(compare checkpoint: Checkpoint) -> Checkpoint? {
    return models.first { $0.path == checkpoint.path }
  }
}

extension CheckpointsManager {
  func addLocalCheckpointsFromDirectoryToModels() {
    guard let directoryUrl = userSettings.stableDiffusionModelsDirectoryUrl else {
      errorMessage = "Directory URL is not set."
      showError = true
      return
    }
    
    do {
      let fileManager = FileManager.default
      let directoryContents = try fileManager.contentsOfDirectory(at: directoryUrl, includingPropertiesForKeys: nil, options: [])
      
      let safetensorFiles = directoryContents.filter { $0.pathExtension == "safetensors" }
      
      let newCheckpoints = safetensorFiles.compactMap { fileUrl -> Checkpoint? in
        let name = fileUrl.deletingPathExtension().lastPathComponent
        let path = fileUrl.path
        
        if !self.models.contains(where: { $0.path == path }) {
          return Checkpoint(name: name, path: path, type: .python, checkpointApiModel: nil)
        }
        return nil
      }
      
      DispatchQueue.main.async {
        self.models.append(contentsOf: newCheckpoints)
      }
    } catch {
      Debug.log("Failed to read directory contents: \(error)")
      DispatchQueue.main.async {
        self.errorMessage = "Failed to load local checkpoints: \(error.localizedDescription)"
        self.showError = true
      }
    }
  }
}
