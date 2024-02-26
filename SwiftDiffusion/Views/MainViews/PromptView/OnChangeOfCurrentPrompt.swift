//
//  OnChangeOfCurrentPrompt.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/25/24.
//

import SwiftUI

// TODO: MAJOR REFACTOR
struct OnChangeOfCurrentPrompt: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var loraModelsManager: ModelManager<LoraModel>
  @EnvironmentObject var vaeModelsManager: ModelManager<VaeModel>
  
  @ObservedObject var scriptManager = ScriptManager.shared
  @ObservedObject var userSettings = UserSettings.shared
  
  var body: some View {
    VStack {
      
    }
    .frame(width: 0, height: 0)
    .onChange(of: currentPrompt.isWorkspaceItem) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.selectedModel) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.samplingMethod) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.positivePrompt) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.negativePrompt) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.width) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.height) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.cfgScale) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.samplingSteps) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.seed) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.batchCount) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.batchSize) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.clipSkip) {
      sidebarViewModel.notifyChange()
    }
    .onChange(of: currentPrompt.vaeModel) {
      sidebarViewModel.notifyChange()
    }
    
  }
}

#Preview {
  OnChange()
}
