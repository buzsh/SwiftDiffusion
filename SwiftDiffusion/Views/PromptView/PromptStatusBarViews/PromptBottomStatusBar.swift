//
//  PromptBottomStatusBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct PromptBottomStatusBar: View {
  @Binding var showingModelPreferences: Bool
  var selectedModel: ModelItem?
  var saveModelPreferences: () -> Void
  
  var body: some View {
    HStack {
      Spacer()
      Button("Save Model Preferences") {
        saveModelPreferences()
      }
      .buttonStyle(.bordered)
      .sheet(isPresented: $showingModelPreferences) {
        if let selectedModel = selectedModel {
          ModelPreferencesView(modelItem: Binding.constant(selectedModel), modelPreferences: selectedModel.preferences)
        }
      }
    }
    .frame(height: 24)
    .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow))
  }
}


#Preview {
  CommonPreviews.promptView
}
