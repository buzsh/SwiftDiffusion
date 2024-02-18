//
//  ModelManagerView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct ModelManagerView: View {
  @EnvironmentObject var checkpointModelsManager: CheckpointModelsManager
  @EnvironmentObject var currentPrompt: PromptModel
  
  @ObservedObject var scriptManager: ScriptManager
  @State private var selectedFilter: ModelType? = nil
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
    guard let selectedFilter = selectedFilter else { return checkpointModelsManager.items }
    return checkpointModelsManager.items.filter { $0.type == selectedFilter }
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        /*
        Button("Reveal in Finder") {
          openUserModelsFolder()
        }
        */
        Button("Refresh") {
          Task {
            await checkpointModelsManager.loadModels()
          }
        }
        
        Menu(filterTitle) { // Use the computed property here
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
          
          Button(action: {
            Debug.log(item)
            self.selectedCheckpointModel = item
          }) {
            Image(systemName: "pencil")
          }
          .buttonStyle(BorderlessButtonStyle())
          
          // if item is not default or if item is not currently selected model
          if !item.isDefaultModel && item != currentPrompt.selectedModel {
            Button(action: {
              Task {
                await checkpointModelsManager.moveToTrash(item: item)
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
      ModelPreferencesView(checkpointModel: Binding<CheckpointModel>(get: { checkpointModel }, set: { _ in }), modelPreferences: checkpointModel.preferences)
    }
    .navigationTitle("Models")
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        HStack {
          
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.5)
          
        }
      }
    }
    
  }
  
  private func openUserModelsFolder() {
    guard let modelsDirUrl = AppDirectory.models.url else {
      Debug.log("modelsDirUrl URL is nil")
      return
    }
    NSWorkspace.shared.open(modelsDirUrl)
  }
}



#Preview {
  return ModelManagerView(scriptManager: ScriptManager.preview(withState: .readyToStart))
    .frame(width: 500, height: 400)
}


