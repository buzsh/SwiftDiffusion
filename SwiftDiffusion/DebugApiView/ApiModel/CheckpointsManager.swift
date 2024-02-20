//
//  CheckpointsManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import Foundation
import Combine

@MainActor
class CheckpointsManager: ObservableObject {
  private var directoryObserver: DirectoryObserver?
  private var userSettings = UserSettings.shared
  private var scriptManager = ScriptManager.shared
  
  @Published var models: [CheckpointModel] = []
  @Published var recentlyRemovedCheckpointModels: [CheckpointModel] = []
  
  @Published var loadedCheckpointModel: CheckpointModel? = nil
  
  @Published var errorMessage: String?
  @Published var showError: Bool = false
  
  private(set) var apiManager: APIManager?
  private var cancellables: Set<AnyCancellable> = []
  
  func configureApiManager(with baseURL: String) {
    self.apiManager = APIManager(baseURL: baseURL)
    Debug.log("configureApiManager with baseURL: \(baseURL)")
    
  }
  
  func startObservingDirectory() {
    guard let directoryUrl = UserSettings.shared.stableDiffusionModelsDirectoryUrl else { return }
    
    Task {
      await removeNonExistentCheckpointsFromPublishedModels()
      await addLocalCheckpointsFromDirectoryToModels()
      await updateCheckpointsFromAPI()
    }
    
    directoryObserver = DirectoryObserver()
    directoryObserver?.startObserving(url: directoryUrl) { [weak self] in
      
      Task {
        await self?.removeNonExistentCheckpointsFromPublishedModels()
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

extension CheckpointsManager {
  func removeNonExistentCheckpointsFromPublishedModels() async {
    let fileManager = FileManager.default
    var removedModels: [CheckpointModel] = []
    
    models = models.filter { model in
      let exists = fileManager.fileExists(atPath: model.path)
      if !exists {
        removedModels.append(model)
      }
      return exists
    }
    
    if !removedModels.isEmpty {
      recentlyRemovedCheckpointModels.append(contentsOf: removedModels)
    }
  }
}


// MARK: Get Loaded API Checkpoint

extension CheckpointsManager {
  func findLoadedCheckpointModel() async -> Result<CheckpointModel?, Error> {
    guard let apiManager = apiManager else {
      let error = NSError(domain: "CheckpointsManagerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "APIManager is not available"])
      return .failure(error)
    }
    
    do {
      // Attempt to update APIManager's loadedCheckpoint
      try await apiManager.getLoadedCheckpointAsync()
      
      // Check for a non-nil loadedCheckpoint
      if let loadedCheckpointTitle = apiManager.loadedCheckpoint {
        // Search for a matching model
        let matchingModel = models.first { $0.checkpointApiModel?.title == loadedCheckpointTitle }
        return .success(matchingModel)
      } else {
        // No loaded checkpoint found
        return .success(nil)
      }
    } catch {
      // Return failure in case of error
      return .failure(error)
    }
  }
  
  func handleLoadedCheckpointModel() async {
    let result = await findLoadedCheckpointModel()
    switch result {
    case .success(let checkpointModel):
      if let model = checkpointModel {
        // Successfully found a model, handle it accordingly
        Debug.log("Found loaded checkpoint model: \(model.name)")
        loadedCheckpointModel = model
        
        scriptManager.updateModelLoadState(to: .done)
        
      } else {
        // No matching model found
        Debug.log("No loaded checkpoint model found")
        
        scriptManager.updateModelLoadState(to: .failed)
        
      }
    case .failure(let error):
      // Handle error
      errorMessage = "Failed to find loaded checkpoint model: \(error.localizedDescription)"
      showError = true
      Debug.log(error.localizedDescription)
      
      scriptManager.updateModelLoadState(to: .failed)
    }
  }
  
}

// MARK: Post Loaded Checkpoint Model

extension CheckpointsManager {
  func postCheckpoint(checkpoint: CheckpointModel?) async -> Result<Void, Error> {
    await withCheckedContinuation { continuation in
      guard let checkpointTitle = checkpoint?.checkpointApiModel?.title else {
        continuation.resume(returning: .failure(NSError(domain: "CheckpointsManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Checkpoint or its title is nil"])))
        return
      }
      
      Task {
        do {
          try await apiManager?.postLoadCheckpointAsync(checkpoint: checkpointTitle)
          continuation.resume(returning: .success(()))
        } catch {
          continuation.resume(returning: .failure(error))
        }
      }
    }
  }
  
  func handlePostCheckpoint(checkpoint: CheckpointModel?) async {
    let result = await postCheckpoint(checkpoint: checkpoint)
    switch result {
    case .success():
      // Handle success, such as updating UI or state
      Debug.log("Checkpoint was successfully posted.")
    case .failure(let error):
      // Handle failure, such as updating UI with an error message
      Debug.log("Failed to post checkpoint: \(error.localizedDescription)")
      errorMessage = "Failed to post checkpoint: \(error.localizedDescription)"
      showError = true
    }
  }
}

/*
extension CheckpointsManager {
  func postCheckpoint(checkpoint: CheckpointModel?) async {
    guard let checkpointTitle = checkpoint?.checkpointApiModel?.title else {
      Debug.log("Checkpoint or checkpoint title is nil")
      // Optionally, update UI to reflect that the operation cannot proceed
      return
    }
    
    do {
      try await apiManager?.postLoadCheckpointAsync(checkpoint: checkpointTitle)
      // Handle success
      Debug.log("Successfully posted checkpoint: \(checkpointTitle)")
      // Here, you can update any relevant state or UI to reflect the success
    } catch {
      // Handle error
      Debug.log("Failed to post checkpoint: \(error.localizedDescription)")
      errorMessage = "Failed to post checkpoint: \(error.localizedDescription)"
      showError = true
    }
  }
}
*/
