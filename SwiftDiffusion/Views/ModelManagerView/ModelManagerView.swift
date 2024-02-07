//
//  ModelManagerView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct ModelItem: Identifiable {
  let id = UUID()
  let name: String
  let type: ModelType
  var isDefaultModel: Bool = false
}

enum ModelType {
  case coreMl
  case python
}

@MainActor
class ModelManagerViewModel: ObservableObject {
  @Published var items: [ModelItem] = []
  
  private let defaultCoreMLModelNames: [String] = ["defaultCoreMLModel1", "defaultCoreMLModel2"]
  private let defaultPythonModelNames: [String] = ["v1-5-pruned-emaonly.safetensors", "defaultPythonModel2"]
  
  func loadModels() async {
    do {
      let fileManager = FileManager.default
      var newItems: [ModelItem] = []
      
      guard let coreMlModelsDir = Constants.FileStructure.coreMlModelsUrl,
            let pythonModelsDir = Constants.FileStructure.pythonModelsUrl else {
        Debug.log("One or more model directories URL is nil")
        return
      }
      
      let coreMLModels = try fileManager.contentsOfDirectory(at: coreMlModelsDir, includingPropertiesForKeys: nil)
      newItems += coreMLModels.filter { $0.hasDirectoryPath }.map {
        ModelItem(name: $0.lastPathComponent, type: .coreMl, isDefaultModel: defaultCoreMLModelNames.contains($0.lastPathComponent))
      }
      
      let pythonModels = try fileManager.contentsOfDirectory(at: pythonModelsDir, includingPropertiesForKeys: nil)
      newItems += pythonModels.filter { $0.pathExtension == "safetensors" }.map {
        ModelItem(name: $0.lastPathComponent, type: .python, isDefaultModel: defaultPythonModelNames.contains($0.lastPathComponent))
      }
      
      self.items = newItems
    } catch {
      Debug.log("Failed to scan directories: \(error)")
    }
  }
}

extension ModelManagerViewModel {
  func moveToTrash(item: ModelItem) async {
    let fileManager = FileManager.default
    do {
      let fileURL: URL // Declare the variable outside the switch
      
      // Safely unwrap URLs
      switch item.type {
      case .coreMl:
        guard let coreMlModelsUrl = Constants.FileStructure.coreMlModelsUrl else {
          Debug.log("CoreML models URL is nil")
          return
        }
        fileURL = coreMlModelsUrl.appendingPathComponent(item.name)
      case .python:
        guard let pythonModelsUrl = Constants.FileStructure.pythonModelsUrl else {
          Debug.log("Python models URL is nil")
          return
        }
        fileURL = pythonModelsUrl.appendingPathComponent(item.name)
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



struct ModelManagerView: View {
  @ObservedObject var scriptManager: ScriptManager
  
  @StateObject private var viewModel = ModelManagerViewModel()
  @State private var selectedFilter: ModelType? = nil
  
  private var filterTitle: String {
    switch selectedFilter {
    case .coreMl:
      return "􀢇 CoreML"
    case .python:
      return "􁻴 Python"
    case .none:
      return "Show All Models"
    }
  }
  
  var filteredItems: [ModelItem] {
    guard let selectedFilter = selectedFilter else { return viewModel.items }
    return viewModel.items.filter { $0.type == selectedFilter }
  }
  
  var isScriptActive: Bool {
    scriptManager.scriptState != .readyToStart
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Button("Reveal in Finder") {
          openUserModelsFolder()
        }
        .disabled(isScriptActive)
        
        Button("Refresh") {
          Task {
            await viewModel.loadModels()
          }
        }.disabled(isScriptActive)
        
        Menu(filterTitle) { // Use the computed property here
          Button("Show All Models", action: { selectedFilter = nil })
          Button("􀢇 CoreML", action: { selectedFilter = .coreMl })
          Button("􁻴 Python", action: { selectedFilter = .python })
        }
        Button("Add Model") {
          Debug.log("Adding model")
        }
        .disabled(isScriptActive)
      }
      .padding(.horizontal)
      .padding(.top, 10)
      
      List(filteredItems, id: \.id) { item in
        HStack {
          
          
          Text(item.name)
          Spacer()
          if !item.isDefaultModel {
            Button(action: {
              Task {
                await viewModel.moveToTrash(item: item)
              }
            }) {
              Image(systemName: isScriptActive ? "lock" : "trash")
            }
            .disabled(isScriptActive)
            .buttonStyle(BorderlessButtonStyle())
          }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
      }
    }
    .onAppear {
      Task {
        await viewModel.loadModels()
      }
    }
  }
  
  private func openUserModelsFolder() {
    guard let userModelsDirUrl = Constants.FileStructure.userModelsUrl else {
      Debug.log("userModelsDirUrl URL is nil")
      return
    }
    NSWorkspace.shared.open(userModelsDirUrl)
  }
}



#Preview {
  ModelManagerView(scriptManager: ScriptManager.readyPreview()).frame(width: 500, height: 400)
}

extension ScriptManager {
  static func readyPreview() -> ScriptManager {
    let previewManager = ScriptManager()
    previewManager.scriptState = .readyToStart
    return previewManager
  }
  
  /*
  static func activePreview() -> ScriptManager {
    let previewManager = ScriptManager()
    previewManager.scriptState = .active
    return previewManager
  }
   */
}
