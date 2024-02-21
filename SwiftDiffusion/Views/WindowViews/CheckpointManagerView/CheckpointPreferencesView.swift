//
//  CheckpointPreferencesView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import CompactSlider
import SwiftUI

struct CheckpointPreferencesView: View {
  @Binding var checkpointModel: CheckpointModel
  @ObservedObject var modelPreferences: CheckpointModelPreferences
  @StateObject private var temporaryPreferences: CheckpointModelPreferences
  @Environment(\.presentationMode) var presentationMode
  
  init(checkpointModel: Binding<CheckpointModel>, modelPreferences: CheckpointModelPreferences) {
    self._checkpointModel = checkpointModel
    self._modelPreferences = ObservedObject(initialValue: modelPreferences)
    self._temporaryPreferences = StateObject(wrappedValue: CheckpointModelPreferences.copy(from: modelPreferences))
  }
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .leading) {
          Text("Model Preferences")
            .font(.system(size: 18)).underline()
            .padding(.bottom, 4)
          Text("Set default properties for loading this model.")
            .padding(.bottom, 4)
          Text(checkpointModel.name)
            .font(.system(.body, design: .monospaced))
            .truncationMode(.middle)
          
          Divider().padding(.top)
          
          samplingMenu
          
          DimensionSelectionRow(width: $temporaryPreferences.width, height: $temporaryPreferences.height)
          
          DetailSelectionRow(cfgScale: $temporaryPreferences.cfgScale, samplingSteps: $temporaryPreferences.samplingSteps)
          
          HStack {
            HalfMaxWidthView {}
            
            CompactSlider(value: $temporaryPreferences.clipSkip, in: 1...12, step: 1) {
              Text("Clip Skip")
              Spacer()
              Text("\(Int(temporaryPreferences.clipSkip))")
            }
          }
          
          //seedSection
        }
        .padding(14)
        .padding(.horizontal, 8)
        .padding(.top, 8)
      }
      
      saveCancelButtons
    }
    .navigationTitle("Model Preferences")
    .frame(minWidth: 300, idealWidth: 400, minHeight: 400, idealHeight: 430)
  }
  
  private var samplingMenu: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Sampling")
      Menu {
        let samplingMethods = checkpointModel.type == .coreMl ? Constants.coreMLSamplingMethods : Constants.pythonSamplingMethods
        ForEach(samplingMethods, id: \.self) { method in
          Button(method) {
            temporaryPreferences.samplingMethod = method
          }
        }
      } label: {
        Label(temporaryPreferences.samplingMethod, systemImage: "square.stack.3d.forward.dottedline")
      }
    }
    .padding(.vertical, Constants.Layout.promptRowPadding)
  }
  
  private var seedSection: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Seed")
        .padding(.leading, 8)
      HStack {
        TextField("", text: $temporaryPreferences.seed)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(.body, design: .monospaced))
        Button(action: {
          temporaryPreferences.seed = "-1"
        }) {
          Image(systemName: "shuffle")
        }
        .buttonStyle(BorderlessButtonStyle())
      }
    }
    .padding(.bottom, Constants.Layout.promptRowPadding)
  }
  
  private var saveCancelButtons: some View {
    HStack {
      Button("Cancel") {
        presentationMode.wrappedValue.dismiss()
      }
      Spacer()
      Button("Save Model Preferences") {
        applyPreferences()
        presentationMode.wrappedValue.dismiss()
      }
    }
    .padding(.horizontal)
    .padding(.bottom, 12)
  }
  
  private func applyPreferences() {
    // TODO: applyPreferences
    //checkpointModel.preferences.update(from: temporaryPreferences)
  }
}

/*
#Preview {
  let item = CheckpointModel(name: "some_model.safetensor", path: "/path/to/package", type: .python)
  item.preferences = CheckpointModelPreferences(samplingMethod: "DPM++ 2M Karras")
  
  return CheckpointPreferencesView(checkpointModel: .constant(item), modelPreferences: item.preferences)
    .frame(width: 400, height: 400)
}
*/

extension CheckpointModelPreferences {
  static func copy(from preferences: CheckpointModelPreferences) -> CheckpointModelPreferences {
    let copy = CheckpointModelPreferences(samplingMethod: preferences.samplingMethod)
    copy.positivePrompt = preferences.positivePrompt
    copy.negativePrompt = preferences.negativePrompt
    copy.width = preferences.width
    copy.height = preferences.height
    copy.cfgScale = preferences.cfgScale
    copy.samplingSteps = preferences.samplingSteps
    copy.clipSkip = preferences.clipSkip
    copy.batchCount = preferences.batchCount
    copy.batchSize = preferences.batchSize
    copy.seed = preferences.seed
    return copy
  }
  
  func update(from preferences: CheckpointModelPreferences) {
    self.samplingMethod = preferences.samplingMethod
    self.positivePrompt = preferences.positivePrompt
    self.negativePrompt = preferences.negativePrompt
    self.width = preferences.width
    self.height = preferences.height
    self.cfgScale = preferences.cfgScale
    self.samplingSteps = preferences.samplingSteps
    self.clipSkip = preferences.clipSkip
    self.batchCount = preferences.batchCount
    self.batchSize = preferences.batchSize
    self.seed = preferences.seed
  }
}
