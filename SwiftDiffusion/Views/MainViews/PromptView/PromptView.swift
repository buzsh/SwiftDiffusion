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
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var loraModelsManager: ModelManager<LoraModel>
  @EnvironmentObject var vaeModelsManager: ModelManager<VaeModel>
  
  @ObservedObject var scriptManager = ScriptManager.shared
  @ObservedObject var userSettings = UserSettings.shared
  
  @State var isRightPaneVisible: Bool = false
  @State var generationDataInPasteboard: Bool = false
  @State var disablePromptView: Bool = false
  
  var currentPrompt: StoredPromptModel
  
  init(currentPrompt: StoredPromptModel) {
    self.currentPrompt = currentPrompt
    _checkpoint = Binding<StoredCheckpointModel?>(
      get: { currentPrompt.selectedModel },
      set: { currentPrompt.selectedModel = $0 }
    )
    _samplingMethod = Binding<String?>(
      get: { currentPrompt.samplingMethod },
      set: { currentPrompt.samplingMethod = $0 }
    )
    _positivePromptText = Binding<String>(
      get: { currentPrompt.positivePrompt },
      set: { currentPrompt.positivePrompt = $0 }
    )
    _negativePromptText = Binding<String>(
      get: { currentPrompt.negativePrompt },
      set: { currentPrompt.negativePrompt = $0 }
    )
    _width = Binding<Double>(
      get: { currentPrompt.width },
      set: { currentPrompt.width = $0 }
    )
    _height = Binding<Double>(
      get: { currentPrompt.height },
      set: { currentPrompt.height = $0 }
    )
    _cfgScale = Binding<Double>(
      get: { currentPrompt.cfgScale },
      set: { currentPrompt.cfgScale = $0 }
    )
    _samplingSteps = Binding<Double>(
      get: { currentPrompt.samplingSteps },
      set: { currentPrompt.samplingSteps = $0 }
    )
    _clipSkip = Binding<Double>(
      get: { currentPrompt.clipSkip },
      set: { currentPrompt.clipSkip = $0 }
    )
    _seed = Binding<String>(
      get: { currentPrompt.seed },
      set: { currentPrompt.seed = $0 }
    )
    _batchCount = Binding<Double>(
      get: { currentPrompt.batchCount },
      set: { currentPrompt.batchCount = $0 }
    )
    _batchSize = Binding<Double>(
      get: { currentPrompt.batchSize },
      set: { currentPrompt.batchSize = $0 }
    )
    _vaeModel = Binding<StoredVaeModel?>(
      get: { currentPrompt.vaeModel },
      set: { currentPrompt.vaeModel = $0 }
    )
  }
  
  @Binding private var checkpoint: StoredCheckpointModel?
  @Binding private var samplingMethod: String?
  @Binding private var positivePromptText: String
  @Binding private var negativePromptText: String
  @Binding private var width: Double
  @Binding private var height: Double
  @Binding private var cfgScale: Double
  @Binding private var samplingSteps: Double
  @Binding private var clipSkip: Double
  @Binding private var seed: String
  @Binding private var batchCount: Double
  @Binding private var batchSize: Double
  
  @Binding private var vaeModel: StoredVaeModel?
  
  private var leftPane: some View {
    VStack(spacing: 0) {
      
      DebugPromptStatusView()
      
      PromptControlBarView()
      
      ScrollView {
        Form {
          if generationDataInPasteboard, let pasteboard = getPasteboardString() {
            HStack {
              Spacer()
              BlueSymbolButton(title: "Paste Generation Data", symbol: "arrow.up.doc.on.clipboard") {
                parseAndSetPromptData(from: pasteboard)
                withAnimation {
                  generationDataInPasteboard = false
                }
              }
            }
            .padding(.top, 14)
          }
          
          HStack {
            CheckpointMenu(modelCheckpoint: $checkpoint)
            SamplingMethodMenu(forCheckpoint: checkpoint, samplingMethod: $samplingMethod)
          }
          .padding(.vertical, 12)
          
          VStack {
            PromptEditorView(label: "Positive Prompt", text: $positivePromptText, isDisabled: $disablePromptView)
            PromptEditorView(label: "Negative Prompt", text: $negativePromptText, isDisabled: $disablePromptView)
          }
          .padding(.bottom, 6)
          
          DimensionSelectionRow(width: $width, height: $height)
          
          DetailSelectionRow(cfgScale: $cfgScale, samplingSteps: $samplingSteps)
          
          HalfSkipClipRow(clipSkip: $clipSkip)
          
          SeedRow(seed: $seed, controlButtonLayout: .beside)
          
          ExportSelectionRow(batchCount: $batchCount, batchSize: $batchSize)
          
          VaeModelMenu(vaeModel: $vaeModel)
        }
        .padding(.leading, 8).padding(.trailing, 16)
        
        .onAppear {
          checkPasteboardAndUpdateFlag()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
          Task {
            await checkPasteboardAndUpdateFlag()
          }
        }
        .disabled(sidebarModel.disablePromptView)
      }
      
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
}
