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
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointModelsManager: CheckpointModelsManager
  @EnvironmentObject var loraModelsManager: ModelManager<LoraModel>
  
  @ObservedObject var scriptManager: ScriptManager
  @ObservedObject var userSettings = UserSettings.shared
  
  @State private var isRightPaneVisible: Bool = false
  @State var generationDataInPasteboard: Bool = false
  @State var disablePromptView: Bool = false
  
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
            CheckpointModelMenu(scriptManager: scriptManager, currentPrompt: currentPrompt, checkpointModelsManager: checkpointModelsManager)
            SamplingMethodMenu(currentPrompt: currentPrompt)
          }
          .padding(.vertical, Constants.Layout.promptRowPadding)
          .frame(minHeight: 90)
          
          VStack {
            PromptEditorView(label: "Positive Prompt", text: $currentPrompt.positivePrompt, isDisabled: $disablePromptView)
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
        .padding(.leading, 8).padding(.trailing, 16)
        
        .onAppear {
          checkPasteboardAndUpdateFlag()
          /*
          if let pasteboardContent = getPasteboardString() {
            generationDataInPasteboard = userHasGenerationDataInPasteboard(from: pasteboardContent)
          }
           */
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
          Task {
            await checkPasteboardAndUpdateFlag()
          }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
          Debug.log("Application did enter background")
        } // Form
        .disabled(disablePromptView)
      } // ScrollView
      
      PasteGenerationDataStatusBar(
        generationDataInPasteboard: generationDataInPasteboard,
        onPaste: { pasteboardContent in
          self.parseAndSetPromptData(from: pasteboardContent)
        }
      )
      
      // PromptBottomStatusBar()
      DebugPromptActionView(scriptManager: scriptManager)
      
    }
    .background(Color(NSColor.windowBackgroundColor))
  }
  
  // TODO: PROMPT QUEUE
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
  
}

#Preview {
  CommonPreviews.promptView
}
