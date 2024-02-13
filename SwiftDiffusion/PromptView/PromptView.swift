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
  @ObservedObject var userSettings = UserSettings.shared
  
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var modelManagerViewModel: ModelManagerViewModel
  
  @ObservedObject var scriptManager: ScriptManager
  
  @State private var isRightPaneVisible: Bool = false
  @State private var columnWidth: CGFloat = 200
  
  @State var generationDataInPasteboard: Bool = false
  
  @State private var appIsActive = true
  @State private var userDidSelectModel = false
  @State var shouldPostNewlySelectedModelCheckpointToApi = false
  @State private var previousSelectedModel: ModelItem?
  
  @State var hasLoadedInitialModel = false
  
  let minColumnWidth: CGFloat = 160
  let minSecondColumnWidth: CGFloat = 160
  
  func updateSelectedCheckpointModelItem(withModelItem modelItem: ModelItem) {
    if previousSelectedModel == modelItem {
      Debug.log("Model already loaded. Do not reload.")
      return
    }
    
    if scriptManager.scriptState == .active {
      scriptManager.modelLoadState = .isLoading
    }
    
    if let modelItem = currentPrompt.selectedModel, let serviceUrl = scriptManager.serviceUrl {
      updateSdModelCheckpoint(forModel: modelItem, apiUrl: serviceUrl) { result in
        switch result {
        case .success(let successMessage):
          // Handle success - you already set scriptManager.modelLoadState = .done in the function
          Debug.log("[updateSdModelCheckpoint] Success: \(successMessage)")
          scriptManager.modelLoadState = .done
        case .failure(let error):
          // Handle failure
          Debug.log("[updateSdModelCheckpoint] Failure: \(error)")
          if hasLoadedInitialModel {
            scriptManager.modelLoadState = .failed // Set the model load state to failed here
          }
        }
      }
    }
    if scriptManager.scriptState == .active {
      previousSelectedModel = modelItem
    }
  }
  
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
        if userSettings.showDebugMenu {
          Button(action: {
            isRightPaneVisible.toggle()
          }) {
            Image(systemName: "apple.terminal") // sidebar.squares.right
          }
        }
      }
    }
  }
  
  private var leftPane: some View {
    VStack(spacing: 0) {
      
      DebugPromptStatusView(scriptManager: scriptManager)
      
      PromptTopStatusBar(
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
              HStack {
                PromptRowHeading(title: "Model")
              }
              HStack {
                Menu {
                  Section(header: Text("􀢇 CoreML")) {
                    ForEach(modelManagerViewModel.items.filter { $0.type == .coreMl }) { item in
                      Button(item.name) {
                        userDidSelectModel = true
                        currentPrompt.selectedModel = item
                        Debug.log("Selected CoreML Model: \(item.name)")
                      }
                    }
                  }
                  Section(header: Text("􁻴 Python")) {
                    ForEach(modelManagerViewModel.items.filter { $0.type == .python }) { item in
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
                if scriptManager.modelLoadState == .isLoading {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5)
                }
              }
            }
            .disabled(!(scriptManager.modelLoadState == .idle || scriptManager.modelLoadState == .done))
            // TODO: REFACTOR FLOW
            .onChange(of: currentPrompt.selectedModel) {
              if let modelToSelect = currentPrompt.selectedModel {
                updateSelectedCheckpointModelItem(withModelItem: modelToSelect)
              }
            }
            .onChange(of: scriptManager.scriptState) {
              if scriptManager.scriptState == .active {
                Task {
                  await modelManagerViewModel.loadModels()
                  //let apiLoadedModel = await getModelMatchingSdModelCheckpoint()
                }
                // if user has already selected a model, load that model
                if let newSelectedModel = currentPrompt.selectedModel {
                  Debug.log("User already selected model. Loading \(newSelectedModel.name)")
                  updateSelectedCheckpointModelItem(withModelItem: newSelectedModel)
                }
              }
            }
            .onChange(of: scriptManager.modelLoadState) {
              // if first load state done, hasLoadedInitialModel = true
              if scriptManager.modelLoadState == .done {
                hasLoadedInitialModel = true
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
          .frame(minHeight: 90)
          
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
      DebugPromptActionView(scriptManager: scriptManager)
      
    }
    .background(Color(NSColor.windowBackgroundColor))
    .frame(minWidth: 240, idealWidth: 320, maxHeight: .infinity)
  }
  
  // TODO: PROMPT QUEUE
  private var rightPane: some View {
    VStack {
      ConsoleView(scriptManager: scriptManager)
    }
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
  }
  
}

#Preview {
  CommonPreviews.promptView
}
