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
  static let listViewPadding: CGFloat = 12
  static let listViewResizableBarPadding = listViewPadding - halfResizableBarWidth
  static let resizableBarWidth: CGFloat = 10
  static let halfResizableBarWidth: CGFloat = resizableBarWidth/2
  static let promptRowPadding: CGFloat = 16
}

struct PromptView: View {
  @EnvironmentObject var currentPrompt: PromptModel
  
  @ObservedObject var modelManager: ModelManagerViewModel
  @ObservedObject var scriptManager: ScriptManager
  @ObservedObject var userSettings: UserSettingsModel
  
  @State private var isRightPaneVisible: Bool = false
  @State private var columnWidth: CGFloat = 200
  
  @State var generationDataInPasteboard: Bool = false
  
  @State private var appIsActive = true
  @State private var userDidSelectModel = false
  @State var shouldPostNewlySelectedModelCheckpointToApi = false
  @State private var previousSelectedModel: ModelItem?
  
  let minColumnWidth: CGFloat = 160
  let minSecondColumnWidth: CGFloat = 160
  
  var body: some View {
    HSplitView {
      leftPane
      if isRightPaneVisible {
        rightPane
      }
    }
    .frame(minWidth: 320, idealWidth: 800, maxHeight: .infinity)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Button(action: {
          isRightPaneVisible.toggle()
        }) {
          Image(systemName: "sidebar.squares.right")
        }
      }
    }
  }
  
  private var leftPane: some View {
    VStack(spacing: 0) {
      
      DebugPromptStatusView(scriptManager: scriptManager, userSettings: userSettings)
      
      PromptTopStatusBar(
        userSettings: userSettings,
        generationDataInPasteboard: generationDataInPasteboard,
        onPaste: { pasteboardContent in
          self.parseAndSetPromptData(from: pasteboardContent)
        }
      )
      
      ScrollView {
        Form {
          HStack {
            // Models
            VStack(alignment: .leading) {
              PromptRowHeading(title: "Model")
              Menu {
                Section(header: Text("􀢇 CoreML")) {
                  ForEach(modelManager.items.filter { $0.type == .coreMl }) { item in
                    Button(item.name) {
                      userDidSelectModel = true
                      currentPrompt.selectedModel = item
                      Debug.log("Selected CoreML Model: \(item.name)")
                    }
                  }
                }
                Section(header: Text("􁻴 Python")) {
                  ForEach(modelManager.items.filter { $0.type == .python }) { item in
                    Button(item.name) {
                      userDidSelectModel = true
                      currentPrompt.selectedModel = item
                      Debug.log("Selected Python Model: \(item.name)")
                    }
                  }
                }
              } label: {
                Label(currentPrompt.selectedModel?.name ?? "Choose Model", systemImage: "arkit") // "skew", "rotate.3d"
              }
            }
            .disabled(!(scriptManager.modelLoadState == .idle || scriptManager.modelLoadState == .done))
            .onAppear {
              modelManager.observeScriptManagerState(scriptManager: scriptManager)
              if scriptManager.scriptState == .readyToStart {
                Task {
                  await modelManager.loadModels()
                  
                }
              }
            }
            .onChange(of: scriptManager.scriptState) {
              if scriptManager.scriptState == .active {
                Task {
                  await selectModelMatchingSdModelCheckpoint()
                }
              }
            }
            .onChange(of: currentPrompt.selectedModel) { newValue in
              if let newValue = newValue, newValue != previousSelectedModel {
                if userDidSelectModel || shouldPostNewlySelectedModelCheckpointToApi {
                  scriptManager.modelLoadState = .isLoading
                  if let modelItem = currentPrompt.selectedModel, let serviceUrl = scriptManager.serviceUrl {
                    updateSdModelCheckpoint(forModel: modelItem, apiUrl: serviceUrl) { result in
                      Debug.log(result)
                    }
                  }
                  userDidSelectModel = false
                  shouldPostNewlySelectedModelCheckpointToApi = false
                  previousSelectedModel = newValue
                }
              }
            }
            .onChange(of: scriptManager.modelLoadState) {
              Debug.log("scriptManager.modelLoadState: \(scriptManager.modelLoadState)")
              if scriptManager.modelLoadState == .done {
                Task {
                  await selectModelMatchingSdModelCheckpoint()
                }
              }
            }
            VStack(alignment: .leading) {
              PromptRowHeading(title: "Sampling")
              Menu {
                let samplingMethods = currentPrompt.selectedModel?.type == .coreMl ? Constants.coreMLSamplingMethods : Constants.pythonSamplingMethods
                ForEach(samplingMethods, id: \.self) { method in
                  Button(method) {
                    currentPrompt.samplingMethod = method
                    Debug.log("Selected Sampling Method: \(method)")
                  }
                }
              } label: {
                Label(currentPrompt.samplingMethod ?? "Choose Sampling Method", systemImage: "square.stack.3d.forward.dottedline")
              }
            }
          }
          .padding(.vertical, Constants.Layout.promptRowPadding)
          
          PromptEditorView(label: "Positive Prompt", text: $currentPrompt.positivePrompt)
          PromptEditorView(label: "Negative Prompt", text: $currentPrompt.negativePrompt)
            .padding(.bottom, 6)
          
          DimensionSelectionRow(width: $currentPrompt.width, height: $currentPrompt.height)
          
          DetailSelectionRow(cfgScale: $currentPrompt.cfgScale, samplingSteps: $currentPrompt.samplingSteps)
          
          HalfSkipClipRow(clipSkip: $currentPrompt.clipSkip)
          
          SeedRow(seed: $currentPrompt.seed, controlButtonLayout: .beside)
          //SeedAndClipSkipRow(seed: $currentPrompt.seed, clipSkip: $currentPrompt.clipSkip)
          //SeedRowAndClipSkipHalfRow(seed: $currentPrompt.seed, clipSkip: $currentPrompt.clipSkip)
          
          ExportSelectionRow(batchCount: $currentPrompt.batchCount, batchSize: $currentPrompt.batchSize)
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .onAppear {
          if let pasteboardContent = getPasteboardString() {
            if userHasGenerationDataInPasteboard(from: pasteboardContent) {
              generationDataInPasteboard = true
            } else {
              generationDataInPasteboard = false
            }
          }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
          Debug.log("[PromptView] willBecomeActiveNotification")
          Task {
            await checkPasteboardAndUpdateFlag()
          }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
          // Handle application going to background if needed
        }
      }
      
      //PromptBottomStatusBar()
      DebugPromptActionView(scriptManager: scriptManager, userSettings: userSettings)
      
    }
    .background(Color(NSColor.windowBackgroundColor))
    .frame(minWidth: 240, idealWidth: 320, maxHeight: .infinity)
  }
  
  private var rightPane: some View {
    VStack {
      Text("Resizable column 2")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
  }
  
}

#Preview {
  CommonPreviews.promptView
}
