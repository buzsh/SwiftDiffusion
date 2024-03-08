//
//  PasteGenerationDataButton.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/7/24.
//

import SwiftUI

struct PasteGenerationDataButton: View {
  @ObservedObject var pastableService = PastableService.shared
  @EnvironmentObject var sidebarModel: SidebarModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var vaeModelsManager: ModelManager<VaeModel>
  
  @State var showButtonWithAnimation: Bool = false
  
  var body: some View {
    HStack {
      if showButtonWithAnimation {
        BlueSymbolButton(title: "Paste", symbol: "arrow.up.doc.on.clipboard") {
          if let pastablePromptData = pastableService.parsePasteboard(checkpoints: checkpointsManager.models, vaeModels: vaeModelsManager.models) {
            sidebarModel.createNewWorkspaceItem(withPrompt: pastablePromptData)
          }
          withAnimation {
            pastableService.clearPasteboard()
            pastableService.canPasteData = false
          }
        }
      }
    }
    .onChange(of: pastableService.canPasteData) {
      withAnimation {
        showButtonWithAnimation = pastableService.canPasteData
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
      Task {
        await pastableService.checkForPastableData()
      }
    }
  }
}


#Preview {
  PasteGenerationDataButton()
    .frame(width: 200, height: 80)
}
