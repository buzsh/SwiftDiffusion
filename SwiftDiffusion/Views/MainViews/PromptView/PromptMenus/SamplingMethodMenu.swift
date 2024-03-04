//
//  SamplingMethodMenu.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import SwiftUI

struct SamplingMethodMenu: View {
  
  var forCheckpoint: StoredCheckpointModel?
  @Binding var samplingMethod: String?
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      PromptRowHeading(title: "Sampling")
        .padding(.bottom, 6)
      Menu {
        let samplingMethods = forCheckpoint?.type == .coreMl
        ? Constants.coreMLSamplingMethods
        : Constants.pythonSamplingMethods
        ForEach(samplingMethods, id: \.self) { method in
          Button(method) {
            samplingMethod = method
            Debug.log("Selected Sampling Method: \(method)")
          }
        }
      } label: {
        Label(samplingMethod ?? "Choose Sampler", systemImage: "square.stack.3d.forward.dottedline")
      }
    }
  }
}

#Preview {
  CommonPreviews.promptView
}
