//
//  ModelPreferencesView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import CompactSlider
import SwiftUI

extension Constants {
  static let coreMLSamplingMethods = ["DPM-Solver++", "PLMS"]
  static let pythonSamplingMethods = [
    "DPM++ 2M Karras", "DPM++ SDE Karras", "DPM++ 2M SDE Exponential", "DPM++ 2M SDE Karras", "Euler a", "Euler", "LMS", "Heun", "DPM2", "DPM2 a", "DPM++ 2S a", "DPM++ 2M", "DPM++ SDE", "DPM++ 2M SDE", "DPM++ 2M SDE Heun", "DPM++ 2M SDE Heun Karras", "DPM++ 2M SDE Heun Exponential", "DPM++ 3M SDE", "DPM++ 3M SDE Karras", "DPM++ 3M SDE Exponential", "DPM fast", "DPM adaptive", "LMS Karras", "DPM2 Karras", "DPM2 a Karras", "DPM++ 2S a Karras", "Restart", "DDIM", "PLMS", "UniPC", "LCM"
  ]
}

struct ModelPreferencesView: View {
  @Binding var modelItem: ModelItem
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .leading) {
          Text(modelItem.name)
            .font(.system(.body, design: .monospaced))
            .truncationMode(.middle)
            .padding(.top, 8)
          
          VStack(alignment: .leading) {
            PromptRowHeading(title: "Sampling")
            Menu {
              let samplingMethods = modelItem.type == .coreMl ? Constants.coreMLSamplingMethods : Constants.pythonSamplingMethods
              ForEach(samplingMethods, id: \.self) { method in
                Button(method) {
                  modelItem.preferences.samplingMethod = method
                  Debug.log("Selected Sampling Method: \(method)")
                }
              }
            } label: {
              Label(modelItem.preferences.samplingMethod , systemImage: "square.stack.3d.forward.dottedline")
            }
          }.padding(.vertical, Constants.Layout.promptRowPadding)
          
          PromptEditorView(label: "Positive Prompt", text: $modelItem.preferences.positivePrompt)
          PromptEditorView(label: "Negative Prompt", text: $modelItem.preferences.negativePrompt)
            .padding(.bottom, 6)
          
          DimensionSelectionRow(width: $modelItem.preferences.width, height: $modelItem.preferences.height)
          
          DetailSelectionRow(cfgScale: $modelItem.preferences.cfgScale, samplingSteps: $modelItem.preferences.samplingSteps)
          
          VStack(alignment: .leading) {
            PromptRowHeading(title: "Seed")
              .padding(.leading, 8)
            HStack {
              TextField("", text: $modelItem.preferences.seed)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .monospaced))
              Button(action: {
                Debug.log("Shuffle random seed")
                modelItem.preferences.seed = "-1"
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
          
          ExportSelectionRow(batchCount: $modelItem.preferences.batchCount, batchSize: $modelItem.preferences.batchSize)
        }.padding(14).padding(.horizontal, 8)
      }
      HStack {
        Spacer()
        Button("Done") {
          presentationMode.wrappedValue.dismiss()
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 8)
    }
    .navigationTitle("Model Preferences")
    .frame(minWidth: 300, idealWidth: 400, minHeight: 350, idealHeight: 600)
  }
}


#Preview {
  var item = ModelItem(name: "some_model.safetensor", type: .python, url: URL(string: "file://path/to/package")!)
  
  return ModelPreferencesView(modelItem: .constant(item))
    .frame(width: 400, height: 600)
}

