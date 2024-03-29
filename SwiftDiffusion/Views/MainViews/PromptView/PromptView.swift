//
//  PromptView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI
import Combine
import CompactSlider

extension Constants.Layout {
  static let promptRowPadding: CGFloat = 16
}

struct PromptView: View {
  @Environment(\.modelContext) var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var loraModelsManager: ModelManager<LoraModel>
  @EnvironmentObject var vaeModelsManager: ModelManager<VaeModel>
  
  @ObservedObject var scriptManager = ScriptManager.shared
  @ObservedObject var userSettings = UserSettings.shared
  
  @State var isRightPaneVisible: Bool = false
  @State var generationDataInPasteboard: Bool = false
  
  private var leftPane: some View {
    VStack(spacing: 0) {
      
      DebugPromptStatusView()
      
      PromptControlBarView()
      
      ScrollView {
        Form {
          HStack {
            CheckpointMenu()
            SamplingMethodMenu()
          }
          .padding(.vertical, 12)
          
          VStack {
            PromptEditorView(label: "Positive Prompt", text: $currentPrompt.positivePrompt)
            PromptEditorView(label: "Negative Prompt", text: $currentPrompt.negativePrompt)
          }
          .padding(.bottom, 6)
          
          DimensionSelectionRow(width: $currentPrompt.width, height: $currentPrompt.height)
          
          DetailSelectionRow(cfgScale: $currentPrompt.cfgScale, samplingSteps: $currentPrompt.samplingSteps)
          
          HalfSkipClipRow(clipSkip: $currentPrompt.clipSkip)
          
          SeedRow(seed: $currentPrompt.seed, controlButtonLayout: .beside)
          
          ExportSelectionRow(batchCount: $currentPrompt.batchCount, batchSize: $currentPrompt.batchSize)
          
          VaeModelMenu()
        }
        .padding(.leading, 8).padding(.trailing, 16)
        .disabled(sidebarModel.disablePromptView)
      }
      .scrollBounceBehavior(.basedOnSize)
      
      DebugPromptActionView(scriptManager: scriptManager)
    }
    .background(Color(NSColor.windowBackgroundColor))
  }
  
  private var rightPane: some View {
    ConsoleView(scriptManager: scriptManager)
      .background(Color(NSColor.windowBackgroundColor))
    
  }
  
  var body: some View {
    HSplitView {
      leftPane
        .frame(minWidth: 370)
      if isRightPaneVisible {
        rightPane
          .frame(minWidth: 370)
      }
    }
  }
}

#Preview {
  CommonPreviews.promptView
    .frame(width: 600, height: 800)
}
