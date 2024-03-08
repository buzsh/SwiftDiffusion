//
//  CheckpointManagerView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct CheckpointManagerView: View {
  @ObservedObject var scriptManager = ScriptManager.shared
  @ObservedObject var userSettings = UserSettings.shared
  var currentPrompt: PromptModel
  var checkpointsManager: CheckpointsManager
  
  @State private var selectedFilter: CheckpointModelType? = nil
  @State private var selectedCheckpointModel: CheckpointModel?
  
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
  
  var filteredItems: [CheckpointModel] {
    let items = selectedFilter == nil ? checkpointsManager.models : checkpointsManager.models.filter { $0.type == selectedFilter }
    return items.sorted { $0.name.lowercased() < $1.name.lowercased() }
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Menu("Reveal in Finder") {
          MenuButton(title: "CoreML Model Checkpoints", symbol: .coreMl, action: openCoreMlCheckpointModelsFolder)
          MenuButton(title: "PyTorch Model Checkpoints", symbol: .python, action: openPythonCheckpointModelsFolder)
        }
        .menuStyle(.borderlessButton)
        
        Menu(filterTitle) {
          MenuButton(title: "Show All Models", symbol: .none, action: { selectedFilter = nil })
          MenuButton(title: "CoreML", symbol: .coreMl, action: { selectedFilter = .coreMl })
          MenuButton(title: "PyTorch", symbol: .python, action: { selectedFilter = .python })
        }
        Button("Add Model") {
          Debug.log("Adding model")
        }
      }
      .padding(.horizontal)
      .padding(.top, 10)
      
      List(filteredItems, id: \.id) { item in
        HStack {
          VStack {
            switch item.type {
            case .coreMl: SFSymbol.coreMl.image
            case .python: SFSymbol.python.image
            }
          }.padding(.trailing, 2)
          
          Text(item.name)
          Spacer()
          
          if item != currentPrompt.selectedModel {
            SymbolButton(symbol: .trash, action: {
              Task {
                await checkpointsManager.moveToTrash(item: item)
              }
            })
          } else {
            SFSymbol.lock.image.opacity(0.3)
          }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
      }
    }
    .navigationTitle("Checkpoint Manager")
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        HStack {
          
        }
      }
    }
    
  }
  
  private func openCoreMlCheckpointModelsFolder() {
    guard let modelsDirUrl = AppDirectory.coreMl.url else {
      Debug.log("coreML dir URL is nil")
      return
    }
    NSWorkspace.shared.open(modelsDirUrl)
  }
  
  private func openPythonCheckpointModelsFolder() {
    guard let modelsDirUrl = userSettings.stableDiffusionModelsDirectoryUrl else {
      Debug.log("stableDiffusionModelsDirectoryUrl URL is nil")
      return
    }
    NSWorkspace.shared.open(modelsDirUrl)
  }
  
  private func openUserModelsFolder() {
    guard let modelsDirUrl = AppDirectory.models.url else {
      Debug.log("modelsDirUrl URL is nil")
      return
    }
    NSWorkspace.shared.open(modelsDirUrl)
  }
}

/*
#Preview {
  return CheckpointManagerView(scriptManager: ScriptManager.preview(withState: .readyToStart))
    .frame(width: 500, height: 400)
}
*/

extension CheckpointsManager {
  func moveToTrash(item: CheckpointModel) async {
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
        let userSettings = UserSettings.shared
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
      SoundUtility.play(systemSound: .trash)
      
      // Reload or update the items list to reflect the change
      //await loadModels()
    } catch {
      Debug.log("Failed to move to trash: \(item.name), error: \(error)")
    }
  }
}

enum SFSymbol: String {
  case coreMl = "rotate.3d"
  case python = "point.bottomleft.forward.to.point.topright.scurvepath"
  case trash
  case lock
  
  case none
  
  var name: String {
    return self.rawValue
  }
  
  var image: some View {
    Image(systemName: self.name)
  }
}

struct MenuButton: View {
  let title: String
  var symbol: SFSymbol = .none
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        if symbol != .none {
          symbol.image
        }
        Text(title)
      }
    }
  }
}

struct SymbolButton: View {
  let symbol: SFSymbol
  let action: () -> Void
  
  var body: some View {
    Button(action: {
      action()
    }) {
      symbol.image
    }
    .buttonStyle(BorderlessButtonStyle())
  }
}
