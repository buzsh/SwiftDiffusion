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
    } catch {
      Debug.log("Failed to load models: \(error)")
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
