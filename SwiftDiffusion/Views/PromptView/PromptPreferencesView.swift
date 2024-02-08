//
//  PromptPreferencesView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import CompactSlider
import SwiftUI

/*
extension Constants {
  static let coreMLSamplingMethods = ["DPM-Solver++", "PLMS"]
  static let pythonSamplingMethods = [
    "DPM++ 2M Karras", "DPM++ SDE Karras", "DPM++ 2M SDE Exponential", "DPM++ 2M SDE Karras", "Euler a", "Euler", "LMS", "Heun", "DPM2", "DPM2 a", "DPM++ 2S a", "DPM++ 2M", "DPM++ SDE", "DPM++ 2M SDE", "DPM++ 2M SDE Heun", "DPM++ 2M SDE Heun Karras", "DPM++ 2M SDE Heun Exponential", "DPM++ 3M SDE", "DPM++ 3M SDE Karras", "DPM++ 3M SDE Exponential", "DPM fast", "DPM adaptive", "LMS Karras", "DPM2 Karras", "DPM2 a Karras", "DPM++ 2S a Karras", "Restart", "DDIM", "PLMS", "UniPC", "LCM"
  ]
}

struct ModelDefaultPreferences {
  var samplingMethod: String? // a value from either coreMLSamplingMethods or pythonSamplingMethods
  var positivePrompt: String?
  var negativePrompt: String?
  var width: Double?
  var height: Double?
  var cfgScale: Double?
  var samplingSteps: Double?
  var clipSkip: Double?
  var batchCount: Double?
  var batchSize: Double?
  var seed: String?
}

struct PromptPreferencesView: View {
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .leading) {
          Text("Model Title")
            .font(.system(.body, design: .monospaced))
            .padding(.vertical, 20)
            .padding(.horizontal, 14)
          
          VStack(alignment: .leading) {
            PromptRowHeading(title: "Sampling")
            Menu {
              let samplingMethods = prompt.selectedModel?.type == .coreMl ? Constants.coreMLSamplingMethods : Constants.pythonSamplingMethods
              ForEach(samplingMethods, id: \.self) { method in
                Button(method) {
                  prompt.samplingMethod = method
                  Debug.log("Selected Sampling Method: \(method)")
                }
              }
            } label: {
              Label(prompt.samplingMethod ?? "Choose Sampling Method", systemImage: "square.stack.3d.forward.dottedline")
            }
          }
          
          PromptEditorView(label: "Positive Prompt", text: $prompt.positivePrompt)
          PromptEditorView(label: "Negative Prompt", text: $prompt.negativePrompt)
            .padding(.bottom, 6)
          
          DimensionSelectionRow(width: $prompt.width, height: $prompt.height)
          
          DetailSelectionRow(cfgScale: $prompt.cfgScale, samplingSteps: $prompt.samplingSteps)
          
          VStack(alignment: .leading) {
            PromptRowHeading(title: "Seed")
              .padding(.leading, 8)
            HStack {
              TextField("", text: $prompt.seed)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .monospaced))
              Button(action: {
                Debug.log("Shuffle random seed")
                prompt.seed = "-1"
              }) {
                Image(systemName: "shuffle") //"dice"
              }
              .buttonStyle(BorderlessButtonStyle())
              Button(action: {
                Debug.log("Repeat last seed")
              }) {
                Image(systemName: "repeat")
              }
              .buttonStyle(BorderlessButtonStyle())
            }
          }
          .padding(.bottom, Constants.Layout.promptRowPadding)
          
          ExportSelectionRow(batchCount: $prompt.batchCount, batchSize: $prompt.batchSize)
        }
      }
      HStack {
        Spacer()
        Button("Done") {
          presentationMode.wrappedValue.dismiss()
        }
      }
    }
    .padding(14)
    .navigationTitle("Settings")
    .frame(minWidth: 500, idealWidth: 670, minHeight: 350, idealHeight: 500)
  }
}

#Preview {
  PromptPreferencesView()
}
*/
