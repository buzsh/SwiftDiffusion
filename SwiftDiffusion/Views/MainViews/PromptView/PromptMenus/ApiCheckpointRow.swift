//
//  ApiCheckpointRow.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/24/24.
//

import SwiftUI

struct ApiCheckpointRow: View {
  @ObservedObject var scriptManager = ScriptManager.shared
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  
  @State var loadedCheckpointName: String = "nil"
  @State private var isExpanded: Bool = true
  
  var body: some View {
    VStack {
      Button(action: {
        self.isExpanded.toggle()
      }) {
        HStack(spacing: 0) {
          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 10, weight: .heavy))
            .frame(minWidth: 12)
            .foregroundStyle(.secondary)
          PromptRowHeading(title: "API Checkpoint Interface")
          Spacer()
        }
      }
      .buttonStyle(.plain)
      
      if isExpanded {
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Menu {
              Section(header: Text("􁻴 API Checkpoints")) {
                ForEach(checkpointsManager.models.filter { $0.type == .python }) { model in
                  Button(model.name) {
                    currentPrompt.selectedModel = model
                  }
                  .disabled(checkpointsManager.hasLoadedInitialCheckpointDataFromApi == false)
                }
              }
            } label: {
              Label(currentPrompt.selectedModel?.name ?? "Loading API checkpoints", systemImage: "arkit")
            }
            
            if scriptManager.modelLoadState == .isLoading || checkpointsManager.apiHasLoadedInitialCheckpointModel == false {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.5)
            } else if scriptManager.modelLoadState == .failed {
              Image(systemName: "exclamationmark.octagon.fill")
                .foregroundStyle(Color.red)
            }
          }
          .disabled(scriptManager.modelLoadState.disableCheckpointMenu)
          .padding(.bottom, 6)
          
          VStack {
            HStack {
              Spacer()
              Text("API Checkpoint: \(loadedCheckpointName)")
                .onChange(of: checkpointsManager.loadedCheckpointModel) {
                  if let checkpoint = checkpointsManager.loadedCheckpointModel {
                    loadedCheckpointName = checkpoint.name
                  } else {
                    loadedCheckpointName = "nil"
                  }
                }
              Spacer()
            }
            
            if scriptManager.modelLoadErrorString != nil {
              
              Divider().foregroundStyle(Color.white)
              
              Text("Error will appear here")
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 4)
            }
          }
          .padding(.vertical, 4)
          .font(.system(size: 12, weight: .regular, design: .monospaced))
          .background(Color.black)
          .foregroundColor(.white)
        }
      }
      
    }
    .padding(.vertical, 10)
    .animation(.default, value: isExpanded)
  }
}

#Preview {
  CommonPreviews.promptView // ApiCheckpointRow()
}
