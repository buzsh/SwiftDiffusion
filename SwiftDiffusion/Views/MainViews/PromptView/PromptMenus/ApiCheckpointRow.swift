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
  @State private var isExpanded: Bool = false
  
  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      VStack(alignment: .leading, spacing: 0) {
        PromptRowHeading(title: "API Checkpoint Interface")
          .padding(.bottom, 6)
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
        }
        .padding(.vertical, 4)
        .font(.system(size: 12, weight: .regular, design: .monospaced))
        .background(Color.black)
        .foregroundColor(.white)
      }
    } label: {
      PromptRowHeading(title: "API Checkpoint Interface") // Custom title view
    }
    .padding(.vertical, 10)
  }
}

#Preview {
  CommonPreviews.promptView // ApiCheckpointRow()
}
