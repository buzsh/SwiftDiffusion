//
//  PromptBottomStatusBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct PromptBottomStatusBar: View {
  @EnvironmentObject var currentPrompt: PromptModel
  
  @State private var showingModelPreferences = false
  
  var body: some View {
    HStack {
      Spacer()
      Button("Save Model Preferences") {
        if let selectedModel = currentPrompt.selectedModel {
          let updatedPreferences = CheckpointModelPreferences(from: currentPrompt)
          selectedModel.preferences = updatedPreferences
          showingModelPreferences = true
        } else {
          Debug.log("[Toast] Error: Please select a model first")
        }
      }
      .disabled(currentPrompt.selectedModel == nil)
      .buttonStyle(.accessoryBar)
      .sheet(isPresented: $showingModelPreferences) {
        if let selectedModel = currentPrompt.selectedModel {
          CheckpointPreferencesView(checkpointModel: Binding.constant(selectedModel), modelPreferences: selectedModel.preferences)
        }
      }
    }
    .frame(height: 24)
    .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow)) //.titlebar
  }
}


#Preview {
  CommonPreviews.promptView
}
