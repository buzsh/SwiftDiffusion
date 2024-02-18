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
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  
  @ObservedObject var scriptManager: ScriptManager
  @ObservedObject var userSettings = UserSettings.shared
  
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointModelsManager: CheckpointModelsManager
  @EnvironmentObject var loraModelsManager: ModelManager<LoraModel>
  
  @State private var isRightPaneVisible: Bool = false
  @State var generationDataInPasteboard: Bool = false
  
  @State var disablePromptView: Bool = false
  
  @State private var previousSelectedModel: CheckpointModel? = nil
  @State var promptViewHasLoadedInitialModel = false
  /// Sends an API request to load in the currently selected model from the PromptView model menu.
  /// - Note: Updates `scriptState` and `modelLoadState`.
  func updateSelectedCheckpointModel(with checkpointModel: CheckpointModel) {
    if previousSelectedModel?.checkpointMetadata?.title == checkpointModel.checkpointMetadata?.title {
      Debug.log("Model already loaded. Do not reload.")
      return
    }
    
    if scriptManager.scriptState.isActive { scriptManager.modelLoadState = .isLoading }
    
    if let checkpointModel = currentPrompt.selectedModel, let serviceUrl = scriptManager.serviceUrl {
      Debug.log("Attempting to updateSdModelCheckpoint with checkpointModel: \(String(describing: checkpointModel.name))")
      updateSdModelCheckpoint(forModel: checkpointModel, apiUrl: serviceUrl) { result in
        switch result {
        case .success(let successMessage):
          Debug.log("[updateSdModelCheckpoint] Success: \(successMessage)")
          scriptManager.modelLoadState = .done
        case .failure(let error):
          Debug.log("[updateSdModelCheckpoint] Failure: \(error)")
          if promptViewHasLoadedInitialModel {
            scriptManager.modelLoadState = .failed
          }
        }
      }
    }
    
    if scriptManager.scriptState.isActive { previousSelectedModel = checkpointModel }
  }
  
  func updateDisabledPromptViewState() {
    guard let isWorkspaceItem = sidebarViewModel.selectedSidebarItem?.isWorkspaceItem else { return }
    disablePromptView = !isWorkspaceItem
  }
  
  func storeChangesOfSelectedSidebarItem() {
    if let isWorkspaceItem = sidebarViewModel.selectedSidebarItem?.isWorkspaceItem, isWorkspaceItem {
      sidebarViewModel.storeChangesOfSelectedSidebarItem(for: currentPrompt, in: modelContext)
    }
    updateDisabledPromptViewState()
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
    .frame(minWidth: isRightPaneVisible ? 740 : 370)
    .toolbar {
      ToolbarItem(placement: .navigation) {
        if userSettings.showDeveloperInterface {
          Button(action: {
            isRightPaneVisible.toggle()
          }) {
            Image(systemName: "apple.terminal")
          }
        }
      }
    }
    .onChange(of: sidebarViewModel.selectedSidebarItem) {
      updateDisabledPromptViewState()
    }
    .onChange(of: sidebarViewModel.itemToSave) {
      updateDisabledPromptViewState()
    }
    .onChange(of: currentPrompt.isWorkspaceItem) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.selectedModel) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.samplingMethod) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.positivePrompt) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.negativePrompt) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.width) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.height) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.cfgScale) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.samplingSteps) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.seed) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.batchCount) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.batchSize) {
      storeChangesOfSelectedSidebarItem()
    }
    .onChange(of: currentPrompt.clipSkip) {
      storeChangesOfSelectedSidebarItem()
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
            // Models Menu
            VStack(alignment: .leading) {
              HStack {
                PromptRowHeading(title: "Model")
              }
              HStack {
                Menu {
                  Section(header: Text("􀢇 CoreML")) {
                    ForEach(checkpointModelsManager.items.filter { $0.type == .coreMl }) { item in
                      Button(item.name) {
                        currentPrompt.selectedModel = item
                        Debug.log("Selected CoreML Model: \(item.name)")
                      }
                    }
                  }
                  Section(header: Text("􁻴 Python")) {
                    ForEach(checkpointModelsManager.items.filter { $0.type == .python }) { item in
                      Button(item.name) {
                        currentPrompt.selectedModel = item
                        Debug.log("Selected Python Model: \(item.name)")
                      }
                    }
                  }
                } label: {
                  Label(currentPrompt.selectedModel?.name ?? "Choose Model", systemImage: "arkit")
                }
                if scriptManager.modelLoadState == .isLoading {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.5)
                }
              }
            }
            .disabled(!(scriptManager.modelLoadState == .idle || scriptManager.modelLoadState == .done))
            .onChange(of: currentPrompt.selectedModel) {
              if let checkpointModel = currentPrompt.selectedModel {
                updateSelectedCheckpointModel(with: checkpointModel)
              }
            }
            .onChange(of: scriptManager.scriptState) {
              if scriptManager.scriptState == .active {
                Task {
                  await checkpointModelsManager.loadModels()
                }
                // if user has already selected a checkpoint model, load that model
                if let checkpointModel = currentPrompt.selectedModel {
                  Debug.log("User already selected model. Loading \(checkpointModel.name)")
                  updateSelectedCheckpointModel(with: checkpointModel)
                }
              }
            }
            .onChange(of: scriptManager.modelLoadState) {
              // if first load state done, promptViewHasLoadedInitialModel = true
              if scriptManager.modelLoadState == .done {
                promptViewHasLoadedInitialModel = true
              }
            }
            .onChange(of: checkpointModelsManager.hasLoadedInitialModelCheckpointsAndAssignedSdModel) {
              Debug.log("checkpointModelsManager.hasLoadedInitialModelCheckpointsAndAssignedSdModel: \(checkpointModelsManager.hasLoadedInitialModelCheckpointsAndAssignedSdModel)")
              if checkpointModelsManager.hasLoadedInitialModelCheckpointsAndAssignedSdModel {
                // if user hasn't yet selected a checkpoint model, fill the menu with the loaded model
                if currentPrompt.selectedModel == nil {
                  Debug.log("User hasn't yet selected a model. Attempting to fill with API loaded model checkpoint...")
                  Task {
                    if let loadedCheckpointModel = await checkpointModelsManager.getModelCheckpointMatchingApiLoadedModelCheckpoint() {
                      currentPrompt.selectedModel = loadedCheckpointModel
                      Debug.log(" - apiLoadedModel: \(String(describing: loadedCheckpointModel.checkpointMetadata?.title))")
                      Debug.log(" - currentPrompt.selectedModel: \(String(describing: currentPrompt.selectedModel?.checkpointMetadata?.title))")
                    }
                  }
                }
              }
            }
            // Sampling Menu
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
          
          VStack {
            PromptEditorView(label: "Positive Prompt", text: $currentPrompt.positivePrompt, isDisabled: $disablePromptView)
              .onChange(of: currentPrompt.positivePrompt) {
                sidebarViewModel.storeChangesOfSelectedSidebarItem(for: currentPrompt, in: modelContext)
              }
            PromptEditorView(label: "Negative Prompt", text: $currentPrompt.negativePrompt, isDisabled: $disablePromptView)
          }
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
          Task {
            await checkPasteboardAndUpdateFlag()
          }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
          // handle application going to background
        }//Form
        .disabled(disablePromptView)
      }//ScrollView
      
      PasteGenerationDataStatusBar(
        generationDataInPasteboard: generationDataInPasteboard,
        onPaste: { pasteboardContent in
          self.parseAndSetPromptData(from: pasteboardContent)
        }
      )
      
      //PromptBottomStatusBar()
      DebugPromptActionView(scriptManager: scriptManager)
      
    }
    .background(Color(NSColor.windowBackgroundColor))
  }
  
  // TODO: PROMPT QUEUE
  private var rightPane: some View {
    ConsoleView(scriptManager: scriptManager)
      .background(Color(NSColor.windowBackgroundColor))
    
  }
  
}

#Preview {
  CommonPreviews.promptView
}
