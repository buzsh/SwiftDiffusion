//
//  CheckpointMenu.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import SwiftUI

struct CheckpointMenu: View {
  @ObservedObject var scriptManager = ScriptManager.shared
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  
  @State var showSelectedCheckpointModelWasRemovedAlert: Bool = false
  @State var showModelLoadTypeErrorThrownAlert: Bool = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      PromptRowHeading(title: "Checkpoint")
        .padding(.bottom, 6)
      HStack {
        Menu {
          Section(header: Text("􀢇 CoreML")) {
            ForEach(checkpointsManager.models.filter { $0.type == .coreMl }
              .sorted(by: { $0.name.lowercased() < $1.name.lowercased() })) { model in
                Button(model.name) {
                  currentPrompt.selectedModel = model
                }
              }
          }
          Section(header: Text("􁻴 Python")) {
            ForEach(checkpointsManager.models.filter { $0.type == .python }
              .sorted(by: { $0.name.lowercased() < $1.name.lowercased() })) { model in
                Button(model.name) {
                  currentPrompt.selectedModel = model
                }
              }
          }
        } label: {
          Label(currentPrompt.selectedModel?.name ?? "Choose Model", systemImage: "arkit")
        }
      }
    }
    
    
    // MARK: Handle Recently Removed
    .onChange(of: checkpointsManager.recentlyRemovedCheckpointModels) {
      handleRecentlyRemovedCheckpointIfSelectedMenuItem()
    }
    .alert(isPresented: $showSelectedCheckpointModelWasRemovedAlert) {
      var message: String = ""
      if let model = currentPrompt.selectedModel { message = model.name }
      
      return Alert(
        title: Text("Warning: Model checkpoint was either moved or deleted"),
        message: Text(message),
        dismissButton: .cancel(Text("OK")) {
          currentPrompt.selectedModel = nil
        }
      )
    }
    .onChange(of: scriptManager.modelLoadTypeErrorThrown) {
      if scriptManager.modelLoadTypeErrorThrown {
        showModelLoadTypeErrorThrownAlert = true
      }
    }
    .alert(isPresented: $showModelLoadTypeErrorThrownAlert) {
      var message: String = ""
      //if let model = currentPrompt.selectedModel { message.append("\(model.name)\n\n") }
      message.append("Don't panic! This is a common issue. For whatever reason, this model has issues loading with RAM optimizations.\n\nOpen the Engine Settings and toggle the 'Disable model loading RAM optimizations' option to ON.")
      
      return Alert(
        title: Text("MPS Framework TypeError"),
        message: Text(message),
        primaryButton: .default(Text("Open Engine Settings")) {
          scriptManager.modelLoadTypeErrorThrown = false
          WindowManager.shared.showSettingsWindow(withTab: SettingsTab.engine)
        },
        secondaryButton: .cancel(Text("Ignore")) {
          scriptManager.modelLoadTypeErrorThrown = false
        }
      )
    }
  }
  
  func handleRecentlyRemovedCheckpointIfSelectedMenuItem() {
    if !checkpointsManager.recentlyRemovedCheckpointModels.isEmpty, let selectedModel = currentPrompt.selectedModel {
      for removedModel in checkpointsManager.recentlyRemovedCheckpointModels {
        if selectedModel.path == removedModel.path {
          showSelectedCheckpointModelWasRemovedAlert = true
        }
      }
    }
    checkpointsManager.recentlyRemovedCheckpointModels = []
  }
}

#Preview {
  CommonPreviews.promptView
}
