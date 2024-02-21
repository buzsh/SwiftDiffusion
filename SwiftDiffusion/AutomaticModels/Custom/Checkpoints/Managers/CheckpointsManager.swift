//
//  CheckpointsManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import Foundation

@MainActor
class CheckpointsManager: ObservableObject {
  private var directoryObserver: DirectoryObserver?
  private var userSettings = UserSettings.shared
  private var scriptManager = ScriptManager.shared
  
  @Published var models: [CheckpointModel] = []
  @Published var recentlyRemovedCheckpointModels: [CheckpointModel] = []
  @Published var loadedCheckpointModel: CheckpointModel? = nil
  @Published var hasLoadedInitialCheckpointDataFromApi: Bool = false
  
  @Published var errorMessage: String?
  @Published var showError: Bool = false
  
  private(set) var apiManager: CheckpointsApiManager?
  func configureApiManager(with baseURL: String) {
    self.apiManager = CheckpointsApiManager(baseURL: baseURL)
    Debug.log("[CheckpointsManager] configureApiManager with baseURL: \(baseURL)")
  }
  
  func startObservingDirectory() {
    Debug.log("[CheckpointsManager] startObservingDirectory()")
    
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
    
    updateFlagForHasLoadedInitialCheckpointDataFromApi(to: false)
  }
}

extension CheckpointsManager {
  func updateFlagForHasLoadedInitialCheckpointDataFromApi(to state: Bool) {
    hasLoadedInitialCheckpointDataFromApi = state
  }
}

extension CheckpointsManager {
  func updateCheckpointsFromAPI() async {
    Debug.log("[CheckpointsManager] Starting updateCheckpointsFromAPI")
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
      updateFlagForHasLoadedInitialCheckpointDataFromApi(to: true)
      
    case .failure(let error):
      errorMessage = "Failed to update checkpoints from API: \(error.localizedDescription)"
      showError = true
      Debug.log(error.localizedDescription)
    }
  }
  
  func checkpointWithPathAlreadyExistsInModels(compare checkpoint: CheckpointModel) -> CheckpointModel? {
    return models.first { $0.path == checkpoint.path }
  }
}


extension CheckpointsManager {
  func refreshAndAssignApiCheckpoints(apiManager: CheckpointsApiManager) async -> Result<String, Error> {
    Debug.log("[CheckpointsManager] refreshAndAssignApiCheckpoints")
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
      try await apiManager.getLoadedCheckpointAsync()
      
      if let loadedCheckpointTitle = apiManager.loadedCheckpoint {
        let matchingModel = models.first { $0.checkpointApiModel?.title == loadedCheckpointTitle }
        return .success(matchingModel)
        
      } else {
        return .success(nil)
        
      }
    } catch {
      return .failure(error)
      
    }
  }
  
  func getLoadedCheckpointModelFromApi() async {
    let result = await findLoadedCheckpointModel()
    switch result {
    case .success(let checkpointModel):
      if let model = checkpointModel {
        Debug.log("[CheckpointsManager] Found loaded checkpoint model: \(model.name)")
        loadedCheckpointModel = model
        scriptManager.updateModelLoadState(to: .done)
        
      } else {
        Debug.log("[CheckpointsManager] No loaded checkpoint model found")
        scriptManager.updateModelLoadState(to: .failed)
        
      }
    case .failure(let error):
      errorMessage = "[CheckpointsManager] Failed to find loaded checkpoint model: \(error.localizedDescription)"
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
      Debug.log("[CheckpointsManager] Checkpoint was successfully posted.")
    case .failure(let error):
      Debug.log("[CheckpointsManager] Failed to post checkpoint: \(error.localizedDescription)")
      errorMessage = "Failed to post checkpoint: \(error.localizedDescription)"
      showError = true
    }
  }
}
