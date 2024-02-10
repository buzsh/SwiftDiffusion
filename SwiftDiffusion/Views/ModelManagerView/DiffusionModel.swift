//
//  DiffusionModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import Combine
import SwiftUI

@MainActor
class ModelManagerViewModel: ObservableObject {
  @Published var items: [ModelItem] = []
  
  private var coreMlObserver: DirectoryObserver?
  private var pythonObserver: DirectoryObserver?
  
  private let defaultCoreMLModelNames: [String] = ["defaultCoreMLModel1", "defaultCoreMLModel2"]
  private let defaultPythonModelNames: [String] = ["v1-5-pruned-emaonly.safetensors", "defaultPythonModel2"]
  
  private let userSettings = UserSettingsModel.shared
  private let scriptManager = ScriptManager.shared
  
  func loadModels() async {
    do {
      let fileManager = FileManager.default
      var newItems: [ModelItem] = []
      let existingURLs = Set(self.items.map { $0.url })
      var updatedURLs = Set<URL>()
      
      // Load CoreML models
      if let coreMlModelsDir = AppDirectory.coreMl.url {
        let coreMlModels = try fileManager.contentsOfDirectory(at: coreMlModelsDir, includingPropertiesForKeys: nil)
        for modelURL in coreMlModels where modelURL.hasDirectoryPath {
          updatedURLs.insert(modelURL)
          if !existingURLs.contains(modelURL) {
            let newItem = ModelItem(name: modelURL.lastPathComponent, type: .coreMl, url: modelURL, isDefaultModel: defaultCoreMLModelNames.contains(modelURL.lastPathComponent))
            newItems.append(newItem)
          }
        }
      }
      
      // Load Python models
      let pythonModelsDir = userSettings.stableDiffusionModelsDirectoryUrl ?? AppDirectory.python.url
      if let pythonModelsDir = pythonModelsDir {
        let pythonModels = try fileManager.contentsOfDirectory(at: pythonModelsDir, includingPropertiesForKeys: nil)
        for modelURL in pythonModels where modelURL.pathExtension == "safetensors" {
          updatedURLs.insert(modelURL)
          if !existingURLs.contains(modelURL) {
            let newItem = ModelItem(name: modelURL.lastPathComponent, type: .python, url: modelURL, isDefaultModel: defaultPythonModelNames.contains(modelURL.lastPathComponent))
            newItems.append(newItem)
          }
        }
      }
      // Remove items whose URLs no longer exist
      self.items = self.items.filter { updatedURLs.contains($0.url) }
      // Add new items
      self.items.append(contentsOf: newItems)
      // Assign model titles if API is connectable
      assignNewModelCheckpointTitles()
    } catch {
      Debug.log("Failed to load models: \(error)")
    }
  }
  
  func assignNewModelCheckpointTitles() {
    assignSdModelCheckpointTitles {
      Debug.log("Assignment of SD Model Checkpoint Titles completed.")
    }
  }
  
  private var scriptManagerObservation: AnyCancellable?
  
  func observeScriptManagerState(scriptManager: ScriptManager) {
    scriptManagerObservation = scriptManager.$scriptState
      .sink { [weak self] state in
        if state == .readyToStart {
          self?.startObservingModelDirectories()
        } else {
          self?.stopObservingModelDirectories()
        }
      }
  }
  
  func stopObservingModelDirectories() {
    coreMlObserver?.stopObserving()
    pythonObserver?.stopObserving()
    // reset observers to nil
    coreMlObserver = nil
    pythonObserver = nil
  }
  
  func startObservingModelDirectories() {
    coreMlObserver = DirectoryObserver()
    pythonObserver = DirectoryObserver()
    
    if let coreMlModelsDir = AppDirectory.coreMl.url {
      coreMlObserver?.startObserving(url: coreMlModelsDir) { [weak self] in
        Debug.log("Detected changes in CoreML models directory")
        await self?.loadModels()
      }
    }
    
    let pythonModelsDir = userSettings.stableDiffusionModelsDirectoryUrl ?? AppDirectory.python.url
    if let pythonModelsDir = pythonModelsDir {
      pythonObserver?.startObserving(url: pythonModelsDir) { [weak self] in
        Debug.log("Detected changes in Python models directory")
        await self?.loadModels()
      }
    }
  }
}

extension ModelManagerViewModel {
  func moveToTrash(item: ModelItem) async {
    let fileManager = FileManager.default
    do {
      let fileURL: URL
      
      switch item.type {
      case .coreMl:
        guard let coreMlModelsDirUrl = AppDirectory.coreMl.url else {
          Debug.log("CoreML models URL is nil")
          return
        }
        fileURL = coreMlModelsDirUrl.appendingPathComponent(item.name)
      case .python:
        let pythonModelsDirUrl = userSettings.stableDiffusionModelsDirectoryUrl ?? AppDirectory.python.url
        guard let pythonModelsDirUrl = pythonModelsDirUrl else {
          Debug.log("Python models URL is nil")
          return
        }
        fileURL = pythonModelsDirUrl.appendingPathComponent(item.name)
      }
      
      // Move the file to trash
      var trashedItemURL: NSURL? = nil
      try fileManager.trashItem(at: fileURL, resultingItemURL: &trashedItemURL)
      Debug.log("Moved to trash: \(item.name)")
      
      // Reload or update the items list to reflect the change
      await loadModels()
    } catch {
      Debug.log("Failed to move to trash: \(item.name), error: \(error)")
    }
  }
}

extension ModelManagerViewModel {
  func getSdModelData(_ api: URL) async throws -> [SdModel] {
    let endpoint = api.appendingPathComponent("/sdapi/v1/sd-models")
    let (data, _) = try await URLSession.shared.data(from: endpoint)
    let decoder = JSONDecoder()
    let models = try decoder.decode([SdModel].self, from: data)
    return models
  }
  
  @MainActor
  func assignSdModelCheckpointTitles(completion: @escaping () -> Void) {
    guard let baseUrl = scriptManager.serviceUrl else {
      completion()
      return
    }
    
    Task {
      do {
        let models = try await getSdModelData(baseUrl)
        var unassignedItems: [ModelItem] = []
        
        // Log all filenames from the API for comparison
        let apiFilenames = models.map { URL(fileURLWithPath: $0.filename).lastPathComponent }
        Debug.log("API Filenames: \(apiFilenames)")
        
        for item in self.items where item.sdModelCheckpoint == nil {
          let itemFilename = item.url.lastPathComponent
          if let matchingModel = models.first(where: { URL(fileURLWithPath: $0.filename).lastPathComponent == itemFilename }) {
            item.sdModelCheckpoint = matchingModel.title
            Debug.log("Assigned \(matchingModel.title) to \(item.name)")
          } else {
            unassignedItems.append(item)
            Debug.log("No match for \(item.name) with filename \(itemFilename)")
          }
        }
        
        // Log unassigned ModelItems
        for item in unassignedItems {
          Debug.log("ModelItem still without sdModelCheckpoint: \(item.name)")
        }
        
        completion()
      } catch {
        Debug.log("Failed to fetch SD Model Data: \(error)")
        completion()
      }
    }
  }
}
