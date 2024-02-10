//
//  PromptBottomStatusBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct PromptBottomStatusBar: View {
  @State private var showingModelPreferences = false
  @ObservedObject var prompt: PromptViewModel
  
  var body: some View {
    HStack {
      Spacer()
      Button("Save Model Preferences") {
        if let selectedModel = prompt.selectedModel {
          let updatedPreferences = ModelPreferences(from: prompt)
          selectedModel.preferences = updatedPreferences
          showingModelPreferences = true
        } else {
          Debug.log("[Toast] Error: Please select a model first")
        }
      }
      .disabled(prompt.selectedModel == nil)
      .buttonStyle(.accessoryBar)
      .sheet(isPresented: $showingModelPreferences) {
        if let selectedModel = prompt.selectedModel {
          ModelPreferencesView(modelItem: Binding.constant(selectedModel), modelPreferences: selectedModel.preferences)
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
