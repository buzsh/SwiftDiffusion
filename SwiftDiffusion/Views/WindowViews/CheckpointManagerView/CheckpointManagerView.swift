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
          Button("CoreML Model Checkpoints", action: openCoreMlCheckpointModelsFolder)
          Button("Python Model Checkpoints", action: openPythonCheckpointModelsFolder)
        }
        .menuStyle(.borderlessButton)
        
        Menu(filterTitle) {
          Button("Show All Models", action: { selectedFilter = nil })
          Button("􀢇 CoreML", action: { selectedFilter = .coreMl })
          Button("􁻴 Python", action: { selectedFilter = .python })
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
            case .coreMl:
              Image(systemName: "rotate.3d")
            case .python:
              Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
            }
          }.padding(.trailing, 2)
          
          Text(item.name)
          Spacer()
          
          /*
          Button(action: {
            Debug.log(item)
            self.selectedCheckpointModel = item
          }) {
            Image(systemName: "pencil")
          }
          .buttonStyle(BorderlessButtonStyle())
          */
          
          // if item is not default or if item is not currently selected model
          if item != currentPrompt.selectedModel {
            Button(action: {
              Task {
                await checkpointsManager.moveToTrash(item: item)
              }
            }) {
              Image(systemName: "trash")
            }
            .buttonStyle(BorderlessButtonStyle())
          } else {
            Image(systemName: "lock").opacity(0.3)
          }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
      }
    }
    .sheet(item: $selectedCheckpointModel) { checkpointModel in
      //CheckpointPreferencesView(checkpointModel: Binding<CheckpointModel>(get: { checkpointModel }, set: { _ in }), modelPreferences: checkpointModel.preferences)
    }
    .navigationTitle("Checkpoint Manager")
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        HStack {
          /*
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.5)
          */
        }
      }
    }
    
  }
  
  private func openCoreMlCheckpointModelsFolder() {
    //guard let modelsDirUrl = userSettings.stableDiffusionModelsDirectoryUrl else {
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
