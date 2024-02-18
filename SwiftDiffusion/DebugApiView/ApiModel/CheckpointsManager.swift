//
//  CheckpointsManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import Foundation

@MainActor
class CheckpointsManager: ObservableObject {
  @Published var models: [CheckpointModel] = []
  
  private var directoryObserver: DirectoryObserver?
  private var userSettings = UserSettings.shared
  
  @Published var errorMessage: String?
  @Published var showError: Bool = false
  
  private(set) var apiManager: APIManager?
  
  func configureApiManager(with baseURL: String) {
    self.apiManager = APIManager(baseURL: baseURL)
    Debug.log("configureApiManager with baseURL: \(baseURL)")
    
  }
  
  func startObservingDirectory() {
    guard let directoryUrl = UserSettings.shared.stableDiffusionModelsDirectoryUrl else { return }
    
    Task {
      await addLocalCheckpointsFromDirectoryToModels()
      await updateCheckpointsFromAPI()
    }
    
    directoryObserver = DirectoryObserver()
    directoryObserver?.startObserving(url: directoryUrl) { [weak self] in
      
      Task {
        await self?.addLocalCheckpointsFromDirectoryToModels()
        await self?.updateCheckpointsFromAPI()
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
    guard let apiManager = apiManager else { Debug.log("apiManager not yet available"); return }
    
    let result = await refreshAndAssignApiCheckpoints(apiManager: apiManager)
    switch result {
    case .success(let message):
      Debug.log(message)
      for apiCheckpoint in apiManager.checkpoints {
        if let existingCheckpoint = checkpointWithPathAlreadyExistsInModels(compare: apiCheckpoint) {
          existingCheckpoint.checkpointApiModel = apiCheckpoint.checkpointApiModel
          Debug.log("apiCheckpoint: \(apiCheckpoint), existingCheckpoint.checkpointApiModel: \(String(describing: existingCheckpoint.checkpointApiModel))")
        }
      }
    case .failure(let error):
      errorMessage = "Failed to update checkpoints from API: \(error.localizedDescription)"
      showError = true
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
  func checkpointWithPathAlreadyExistsInModels(compare checkpoint: CheckpointModel) -> CheckpointModel? {
    return models.first { $0.path == checkpoint.path }
  }
}

extension CheckpointsManager {
  func addLocalCheckpointsFromDirectoryToModels() async {
    guard let directoryUrl = userSettings.stableDiffusionModelsDirectoryUrl else {
      errorMessage = "Directory URL is not set."
      showError = true
      return
    }
    
    do {
      let fileManager = FileManager.default
      let directoryContents = try fileManager.contentsOfDirectory(at: directoryUrl, includingPropertiesForKeys: nil, options: [])
      
      let safetensorFiles = directoryContents.filter { $0.pathExtension == "safetensors" }
      
      let newCheckpoints = safetensorFiles.compactMap { fileUrl -> CheckpointModel? in
        let name = fileUrl.lastPathComponent //fileUrl.deletingPathExtension().lastPathComponent
        let path = fileUrl.path
        
        if !self.models.contains(where: { $0.path == path }) {
          return CheckpointModel(name: name, path: path, type: .python, checkpointApiModel: nil)
        }
        return nil
      }
      
      self.models.append(contentsOf: newCheckpoints)
    } catch {
      self.errorMessage = "Failed to load local checkpoints: \(error.localizedDescription)"
      self.showError = true
    }
  }
}
