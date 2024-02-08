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
          
          VStack(alignment: .leading) {
            PromptRowHeading(title: "Seed")
              .padding(.leading, 8)
            HStack {
              TextField("", text: $prompt.seed)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .monospaced))
              Button(action: {
                Debug.log("Shuffle random seed")
                prompt.seed = "-1"
              }) {
                Image(systemName: "shuffle") //"dice"
              }
              .buttonStyle(BorderlessButtonStyle())
              Button(action: {
                Debug.log("Repeat last seed")
              }) {
                Image(systemName: "repeat")
              }
              .buttonStyle(BorderlessButtonStyle())
            }
          }
          .padding(.bottom, Constants.Layout.promptRowPadding)
          
          ExportSelectionRow(batchCount: $prompt.batchCount, batchSize: $prompt.batchSize)
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
      }
      
      HStack {
        Spacer()
        Button("Save Model Preferences") {
          Debug.log("Save model default")
        }
        .buttonStyle(.accessoryBar)
        Button(action: {
          Debug.log("Toolbar item selected")
        }) {
          Image(systemName: "questionmark.circle")
        }
        .buttonStyle(.accessoryBar)
        .padding(.trailing, 8)
      }
      .frame(height: 24)
      .background(VisualEffectBlurView(material: .sheet, blendingMode: .behindWindow))//.titlebar
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


#Preview("Left Prompt View") {
  let modelManager = ModelManagerViewModel()
  
  let promptModel = PromptViewModel()
  promptModel.positivePrompt = "sample, positive, prompt"
  promptModel.negativePrompt = "sample, negative, prompt"
  
  return PromptView(prompt: promptModel, modelManager: modelManager, scriptManager: ScriptManager.readyPreview()).frame(width: 400, height: 600)
}



struct PromptRowHeading: View {
  var title: String
  
  var body: some View {
    Text(title)
      .textCase(.uppercase)
      .font(.system(size: 11, weight: .bold, design: .rounded))
      .opacity(0.8)
      .padding(.horizontal, 8)
  }
  
}

struct DimensionSelectionRow: View {
  @Binding var width: Double
  @Binding var height: Double
  
  var body: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Dimensions")
      HStack {
        CompactSlider(value: $width, in: 64...2048, step: 64) {
          Text("Width")
          Spacer()
          Text("\(Int(width))")
        }
        CompactSlider(value: $height, in: 64...2048, step: 64) {
          Text("Height")
          Spacer()
          Text("\(Int(height))")
        }
      }
    }
    .padding(.bottom, Constants.Layout.promptRowPadding)
  }
}

struct DetailSelectionRow: View {
  @Binding var cfgScale: Double
  @Binding var samplingSteps: Double
  
  var body: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Detail")
      HStack {
        CompactSlider(value: $cfgScale, in: 1...30, step: 0.5) {
          Text("CFG Scale")
          Spacer()
          Text(String(format: "%.1f", cfgScale))
        }
        CompactSlider(value: $samplingSteps, in: 1...150, step: 1) {
          Text("Sampling Steps")
          Spacer()
          Text("\(Int(samplingSteps))")
        }
      }
    }
    .padding(.bottom, Constants.Layout.promptRowPadding)
  }
}

struct ExportSelectionRow: View {
  @Binding var batchCount: Double
  @Binding var batchSize: Double
  
  var body: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Export Amount")
      HStack {
        CompactSlider(value: $batchCount, in: 1...100, step: 1) {
          Text("Batch Count")
          Spacer()
          Text("\(Int(batchCount))")
        }
        CompactSlider(value: $batchSize, in: 1...8, step: 1) {
          Text("Batch Size")
          Spacer()
          Text("\(Int(batchSize))")
        }
      }
    }
    .padding(.bottom, Constants.Layout.promptRowPadding)
  }
}

