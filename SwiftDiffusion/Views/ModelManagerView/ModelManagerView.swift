//
//  ModelManagerView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct ModelManagerView: View {
  @ObservedObject var scriptManager: ScriptManager
  
  @ObservedObject var viewModel = ModelManagerViewModel()
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
          } else {
            Image(systemName: "lock").opacity(0.3)
          }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
      }
    }
    .onAppear {
      viewModel.observeScriptManagerState(scriptManager: scriptManager)
      if scriptManager.scriptState == .readyToStart {
        Task {
          await viewModel.loadModels()
        }
      }
    }
    
  }
  
  private func openUserModelsFolder() {
    guard let modelsDirUrl = DirectoryPath.models.url else {
      Debug.log("modelsDirUrl URL is nil")
      return
    }
    NSWorkspace.shared.open(modelsDirUrl)
  }
}



#Preview {
  ModelManagerView(scriptManager: ScriptManager.readyPreview()).frame(width: 500, height: 400)
}

extension ScriptManager {
  static func readyPreview() -> ScriptManager {
    let previewManager = ScriptManager()
    previewManager.scriptState = .readyToStart // .active
    return previewManager
  }
}
