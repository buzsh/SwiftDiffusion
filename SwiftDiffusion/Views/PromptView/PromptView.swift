//
//  PromptView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI
import CompactSlider

extension Constants.Layout {
  static let listViewPadding: CGFloat = 12
  static let listViewResizableBarPadding = listViewPadding - halfResizableBarWidth
  static let resizableBarWidth: CGFloat = 10
  static let halfResizableBarWidth: CGFloat = resizableBarWidth/2
  static let promptRowPadding: CGFloat = 16
}

struct PromptView: View {
  @ObservedObject var prompt: PromptViewModel
  @ObservedObject var modelManager: ModelManagerViewModel
  @ObservedObject var scriptManager: ScriptManager
  
  @State private var showingModelPreferences = false
  @State private var isRightPaneVisible: Bool = false
  @State private var columnWidth: CGFloat = 200
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
                      prompt.selectedModel = item
                      Debug.log("Selected CoreML Model: \(item.name)")
                    }
                  }
                }
                Section(header: Text("􁻴 Python")) {
                  ForEach(modelManager.items.filter { $0.type == .python }) { item in
                    Button(item.name) {
                      prompt.selectedModel = item
                      Debug.log("Selected Python Model: \(item.name)")
                    }
                  }
                }
              } label: {
                Label(prompt.selectedModel?.name ?? "Choose Model", systemImage: "arkit") // "skew", "rotate.3d"
              }
            }
            .onAppear {
              modelManager.observeScriptManagerState(scriptManager: scriptManager)
              if scriptManager.scriptState == .readyToStart {
                Task {
                  await modelManager.loadModels()
                }
              }
            }
            
            // Sampling
            VStack(alignment: .leading) {
              PromptRowHeading(title: "Sampling")
              Menu {
                let samplingMethods = prompt.selectedModel?.type == .coreMl ? Constants.coreMLSamplingMethods : Constants.pythonSamplingMethods
                ForEach(samplingMethods, id: \.self) { method in
                  Button(method) {
                    prompt.samplingMethod = method
                    Debug.log("Selected Sampling Method: \(method)")
                  }
                }
              } label: {
                Label(prompt.samplingMethod ?? "Choose Sampling Method", systemImage: "square.stack.3d.forward.dottedline")
              }
            }
          }
          .padding(.vertical, Constants.Layout.promptRowPadding)
          
          PromptEditorView(label: "Positive Prompt", text: $prompt.positivePrompt)
          PromptEditorView(label: "Negative Prompt", text: $prompt.negativePrompt)
            .padding(.bottom, 6)
          
          DimensionSelectionRow(width: $prompt.width, height: $prompt.height)
          
          DetailSelectionRow(cfgScale: $prompt.cfgScale, samplingSteps: $prompt.samplingSteps)
          
          HalfSkipClipRow(clipSkip: $prompt.clipSkip)
          
          SeedRow(seed: $prompt.seed, controlButtonLayout: .beside)
          //SeedAndClipSkipRow(seed: $prompt.seed, clipSkip: $prompt.clipSkip)
          //SeedRowAndClipSkipHalfRow(seed: $prompt.seed, clipSkip: $prompt.clipSkip)
          
          ExportSelectionRow(batchCount: $prompt.batchCount, batchSize: $prompt.batchSize)
          
          HStack {
            Spacer()
            Button("Debug.log all variables") {
              logAllVariables()
            }
            
            Button("Paste and parse data") {
              if let pasteboardContent = getPasteboardString() {
                parseAndSetPromptData(from: pasteboardContent)
              }
            }
            Spacer()
          }
          .padding()
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
      }
      
      HStack {
        Spacer()
        Button("Save Model Preferences") {
          if let selectedModel = prompt.selectedModel {
            let updatedPreferences = ModelPreferences(from: prompt)
            selectedModel.preferences = updatedPreferences
            showingModelPreferences = true
          } else {
            Debug.log("[Toast] Error: Please select a model first")
          }
        }
        .buttonStyle(.accessoryBar)
        .sheet(isPresented: $showingModelPreferences) {
          if let selectedModel = prompt.selectedModel {
            ModelPreferencesView(modelItem: Binding.constant(selectedModel), modelPreferences: selectedModel.preferences)
          }
        }
        
      }
      .frame(height: 24)
      .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow)) //.titlebar
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
  
  func logAllVariables() {
    var debugOutput = ""
    
    debugOutput += "selectedModel: \(prompt.selectedModel?.name ?? "nil")\n"
    debugOutput += "samplingMethod: \(prompt.samplingMethod ?? "nil")\n"
    debugOutput += "positivePrompt: \(prompt.positivePrompt)\n"
    debugOutput += "negativePrompt: \(prompt.negativePrompt)\n"
    debugOutput += "width: \(prompt.width)\n"
    debugOutput += "height: \(prompt.height)\n"
    debugOutput += "cfgScale: \(prompt.cfgScale)\n"
    debugOutput += "samplingSteps: \(prompt.samplingSteps)\n"
    debugOutput += "seed: \(prompt.seed)\n"
    debugOutput += "batchCount: \(prompt.batchCount)\n"
    debugOutput += "batchSize: \(prompt.batchSize)\n"
    debugOutput += "clipSkip: \(prompt.clipSkip)\n"
    
    Debug.log(debugOutput) // Assuming Debug.log can accept a String argument and functions like print().
  }
}


#Preview("Left Prompt View") {
  let modelManager = ModelManagerViewModel()
  
  let promptModel = PromptViewModel()
  promptModel.positivePrompt = "sample, positive, prompt"
  promptModel.negativePrompt = "sample, negative, prompt"
  
  return PromptView(prompt: promptModel, modelManager: modelManager, scriptManager: ScriptManager.readyPreview()).frame(width: 400, height: 600)
}

extension PromptView {
  
  func getPasteboardString() -> String? {
    return NSPasteboard.general.string(forType: .string)
  }
  
  func normalizeModelName(_ name: String) -> String {
    let lowercased = name.lowercased()
    let alphanumeric = lowercased.filter { $0.isLetter || $0.isNumber }
    return alphanumeric
  }
  
  func parseAndSetPromptData(from pasteboardContent: String) {
    let lines = pasteboardContent.split(separator: "\n", omittingEmptySubsequences: true)
    Debug.log(lines)
    if let positivePromptLine = lines.first {
      prompt.positivePrompt = String(positivePromptLine)
    }
    
    for line in lines {
      if line.starts(with: "Negative prompt:") {
        let negativePrompt = line.replacingOccurrences(of: "Negative prompt: ", with: "")
        prompt.negativePrompt = negativePrompt
      } else if line.starts(with: "Steps:") {
        let steps = line.split(separator: ",").first?.replacingOccurrences(of: "Steps: ", with: "")
        if let stepsValue = Double(steps ?? "") {
          prompt.samplingSteps = stepsValue
        }
      } else if line.starts(with: "Size:") {
        let sizeComponents = line.replacingOccurrences(of: "Size: ", with: "").split(separator: "x")
        if sizeComponents.count == 2, let width = Double(sizeComponents[0]), let height = Double(sizeComponents[1]) {
          prompt.width = width
          prompt.height = height
        }
      } else if line.starts(with: "Seed:") {
        let seed = line.replacingOccurrences(of: "Seed: ", with: "")
        prompt.seed = seed
      } else if line.starts(with: "Sampler:") {
        let sampler = line.replacingOccurrences(of: "Sampler: ", with: "")
        prompt.samplingMethod = sampler
      } else if line.starts(with: "CFG scale:") {
        let cfgScale = line.split(separator: ",").first?.replacingOccurrences(of: "CFG scale: ", with: "")
        Debug.log("CFG: \(cfgScale)")
        if let cfgScaleValue = Double(cfgScale ?? "") {
          prompt.cfgScale = cfgScaleValue
        }
      } else if line.starts(with: "Clip skip:") {
        let clipSkip = line.split(separator: ",").first?.replacingOccurrences(of: "Clip skip: ", with: "")
        if let clipSkipValue = Double(clipSkip ?? "") {
          prompt.clipSkip = clipSkipValue
        }
        
      } else if line.starts(with: "Model:") {
        let parsedModelName = line.replacingOccurrences(of: "Model: ", with: "")
        let normalizedParsedModelName = normalizeModelName(parsedModelName)
        
        // Find a matching model
        if let matchingModel = modelManager.items.first(where: { item in
          let normalizedItemName = normalizeModelName(item.name)
          return normalizedItemName.contains(normalizedParsedModelName) || normalizedParsedModelName.contains(normalizedItemName)
        }) {
          prompt.selectedModel = matchingModel
        }
      }
      
      
    }
  }
  
  
}
