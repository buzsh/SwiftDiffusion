//
//  VaeModelMenu.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/25/24.
//

import SwiftUI

struct VaeModelMenu: View {
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var vaeModelsManager: ModelManager<VaeModel>
  
  @State private var isExpanded: Bool = true
  
  var body: some View {
    VStack {
      ExpandableSectionHeader(title: "VAE", isExpanded: $isExpanded)
      
      if isExpanded {
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Menu {
              ForEach(vaeModelsManager.models, id: \.id) { vae in
                Button(vae.name) {
                  currentPrompt.vaeModel = vae
                }
              }
            } label: {
              Label(currentPrompt.vaeModel?.name ?? "None", systemImage: "arkit")
            }
          }
        }
      }
      
    }
    .padding(.vertical, 10)
  }
}

#Preview {
  CommonPreviews.promptView
}
