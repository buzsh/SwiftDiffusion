//
//  ContentView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI

extension Constants.Layout {
  static let verticalPadding: CGFloat = 8
}

enum ViewManager {
  case prompt, console, models, settings
  
  var title: String {
    switch self {
    case .prompt: return "Prompt"
    case .console: return "Console"
    case .models: return "Models"
    case .settings: return "Settings"
    }
  }
}

extension ViewManager: Hashable, Identifiable {
  var id: Self { self }
}

struct ContentView: View {
  // Toolbar
  @State private var showingSettingsView = false
  @ObservedObject var modelManagerViewModel: ModelManagerViewModel
  // Prompt
  @ObservedObject var promptViewModel: PromptViewModel
  // Console
  @ObservedObject var scriptManager: ScriptManager
  @Binding var scriptPathInput: String
  @Binding var fileOutputDir: String
  // Views
  @State private var selectedView: ViewManager = .prompt
  // Detail
  @StateObject var fileHierarchy = FileHierarchy(rootPath: "")
  @State var selectedImage: NSImage? = NSImage(named: "DiffusionPlaceholder")
  @AppStorage("lastSelectedImagePath") var lastSelectedImagePath: String = ""
  
  @StateObject var userSettingsModel: UserSettingsModel
  
  @State private var hasFirstAppeared = false
  
  var body: some View {
    NavigationSplitView {
      // Sidebar
      List {
        NavigationLink(value: ViewManager.prompt) {
          Label("Prompt", systemImage: "text.bubble")
        }
        NavigationLink(value: ViewManager.console) {
          Label("Console", systemImage: "terminal")
        }
      }
      .listStyle(SidebarListStyle())
      
    } content: {
      switch selectedView {
      case .prompt:
        PromptView(prompt: promptViewModel, modelManager: modelManagerViewModel, scriptManager: scriptManager, userSettings: userSettingsModel)
      case .console:
        ConsoleView(scriptManager: scriptManager, scriptPathInput: $scriptPathInput)
      case .models:
        ModelManagerView(scriptManager: scriptManager, viewModel: modelManagerViewModel)
      case .settings:
        SettingsView(userSettings: userSettingsModel, scriptPathInput: $scriptPathInput, fileOutputDir: $fileOutputDir)
      }
    } detail: {
      // Image, FileSelect DetailView
      DetailView(fileHierarchyObject: fileHierarchy, selectedImage: $selectedImage, lastSelectedImagePath: $lastSelectedImagePath, scriptManager: scriptManager)
    }
    .background(VisualEffectBlurView(material: .headerView, blendingMode: .behindWindow))
    .onAppear {
      scriptPathInput = scriptManager.scriptPath ?? ""
      fileHierarchy.rootPath = fileOutputDir
      Task {
        await fileHierarchy.refresh()
        await loadLastSelectedImage()
      }
      if scriptManager.scriptState == .readyToStart {
        modelManagerViewModel.startObservingModelDirectories()
      }
      handleScriptOnLaunch()
    }
    .onChange(of: fileOutputDir) {
      fileHierarchy.rootPath = fileOutputDir
      Task {
        await fileHierarchy.refresh()
      }
    }
    .navigationTitle(selectedView.title)
    .toolbar {
      ToolbarItemGroup(placement: .navigation) {
        HStack {
          Button(action: {
            if scriptManager.scriptState == .readyToStart {
              scriptManager.scriptPath = scriptPathInput
              scriptManager.run()
            } else {
              scriptManager.terminate()
            }
          }) {
            if scriptManager.scriptState == .readyToStart {
              Image(systemName: "play.fill")
            } else {
              Image(systemName: "stop.fill")
            }
          }.disabled(scriptManager.scriptState.isAwaitingProcessToPlayOut)
          
          Circle()
            .fill(scriptManager.scriptState.statusColor)
            .frame(width: 10, height: 10)
            .padding(.trailing, 2)
          
          if scriptManager.scriptState == .active, let url = scriptManager.serviceUrl {
            Button(action: {
              NSWorkspace.shared.open(url)
            }) {
              Image(systemName: "network")
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
          }
        }
      }
      
      ToolbarItemGroup(placement: .automatic) {
        HStack {
          
          if scriptManager.genStatus == .generating || scriptManager.genStatus == .finishingUp {
            Text("\(Int(scriptManager.genProgress * 100))%")
              .font(.system(.body, design: .monospaced))
          } else if scriptManager.genStatus == .preparingToGenerate {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(0.5)
          } else if scriptManager.genStatus == .done {
            Image(systemName: "checkmark.seal.fill")
              .foregroundStyle(Color.green)
          }
          
          Button(action: {
            Task {
              await prepareAndSendAPIRequest()
            }
          }) {
            Text("Generate")
          }
          
          Picker("Options", selection: $selectedView) {
            Text("Prompt").tag(ViewManager.prompt)
            Text("Console").tag(ViewManager.console)
            Text("Models").tag(ViewManager.models)
          }
          .pickerStyle(SegmentedPickerStyle())
          
          Button(action: {
            Debug.log("Testing api")
            
            //showingSettingsView = true

          }) {
            Image(systemName: "arkit")
          }
          Button(action: {
            Debug.log("Toolbar item selected")
            showingSettingsView = true
          }) {
            Image(systemName: "gear")
          }
        }
      }
      
      
    }
    .sheet(isPresented: $showingSettingsView) {
      SettingsView(userSettings: userSettingsModel, scriptPathInput: $scriptPathInput, fileOutputDir: $fileOutputDir)
    }
  }
  
  private func loadLastSelectedImage() async {
    if !lastSelectedImagePath.isEmpty, let image = NSImage(contentsOfFile: lastSelectedImagePath) {
      await MainActor.run {
        self.selectedImage = image
      }
    }
  }
  
}


#Preview {
  let modelManager = ModelManagerViewModel()
  let promptModel = PromptViewModel()
  promptModel.positivePrompt = "sample, positive, prompt"
  promptModel.negativePrompt = "sample, negative, prompt"
  return ContentView(modelManagerViewModel: modelManager, promptViewModel: promptModel, scriptManager: ScriptManager.readyPreview(), scriptPathInput: .constant("path/to/webui.sh"), fileOutputDir: .constant("path/to/output"), userSettingsModel: UserSettingsModel.preview())
    .frame(height: 700)
}


extension ContentView {
  func handleScriptOnLaunch() {
    if userSettingsModel.alwaysStartPythonEnvironmentAtLaunch {
      if !self.hasFirstAppeared {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
          Debug.log("Running in SwiftUI Preview, skipping script execution and model loading.")
        } else {
          Debug.log("First appearance. Starting script...")
          scriptManager.run()
          self.hasFirstAppeared = true
          
          Task {
            await modelManagerViewModel.loadModels()
          }
        }
      }
    }
  }
}
