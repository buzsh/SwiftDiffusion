//
//  PromptRows.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI
import CompactSlider

#Preview {
  let modelManager = ModelManagerViewModel()
  
  let promptModelPreview = PromptModel()
  promptModelPreview.positivePrompt = "sample, positive, prompt"
  promptModelPreview.negativePrompt = "sample, negative, prompt"
  
  return PromptView(modelManager: modelManager, scriptManager: ScriptManager.preview(withState: .readyToStart), userSettings: UserSettingsModel.preview())
    .environmentObject(promptModelPreview)
    .frame(width: 400, height: 600)
}


struct PromptRowHeading: View {
  var title: String
  
  var body: some View {
    Text(title)
      .textCase(.uppercase)
      .font(.system(size: 11, weight: .bold, design: .rounded))
      .opacity(0.8)
      .padding(.horizontal, 8)
  }
  
}

struct DimensionSelectionRow: View {
  @Binding var width: Double
  @Binding var height: Double
  
  var body: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Dimensions")
      HStack {
        CompactSlider(value: $width, in: 64...2048, step: 64) {
          Text("Width")
          Spacer()
          Text("\(Int(width))")
        }
        CompactSlider(value: $height, in: 64...2048, step: 64) {
          Text("Height")
          Spacer()
          Text("\(Int(height))")
        }
      }
    }
    .padding(.bottom, Constants.Layout.promptRowPadding)
  }
}

struct DetailSelectionRow: View {
  @Binding var cfgScale: Double
  @Binding var samplingSteps: Double
  
  var body: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Detail")
      HStack {
        CompactSlider(value: $cfgScale, in: 1...30, step: 0.5) {
          Text("CFG Scale")
          Spacer()
          Text(String(format: "%.1f", cfgScale))
        }
        CompactSlider(value: $samplingSteps, in: 1...150, step: 1) {
          Text("Sampling Steps")
          Spacer()
          Text("\(Int(samplingSteps))")
        }
      }
    }//.padding(.bottom, Constants.Layout.promptRowPadding)
  }
}

struct HalfSkipClipRow: View {
  @Binding var clipSkip: Double
  
  var body: some View {
    VStack {
      HStack {
        HalfMaxWidthView {}
        CompactSlider(value: $clipSkip, in: 1...12, step: 1) {
          Text("Clip Skip")
          Spacer()
          Text("\(Int(clipSkip))")
        }
      }
    }
  }
}


