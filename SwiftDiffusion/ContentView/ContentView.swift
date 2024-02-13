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
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var modelManagerViewModel: ModelManagerViewModel
  
  @ObservedObject var userSettings = UserSettings.shared
  @ObservedObject var scriptManager: ScriptManager

  // RequiredInputPaths
  @State private var showingRequiredInputPathsView = false
  @State private var hasDismissedRequiredInputPathsView = false
  @State private var isPulsating = false
  
  // TabView
  @State private var selectedView: ViewManager = .prompt
  
  @State private var hasLaunchedPythonEnvironmentOnFirstAppearance = false
  @State private var launchStatusProgressBarValue: Double = 0
  
  // Detail
  @StateObject var fileHierarchy = FileHierarchy(rootPath: "")
  @State var selectedImage: NSImage? = NSImage(named: "DiffusionPlaceholder")
  @AppStorage("lastSelectedImagePath") var lastSelectedImagePath: String = ""
  
  
  
  @State var imageCountToGenerate: Int = 0
  
  @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      List {}
      .listStyle(SidebarListStyle())
    } content: {
      switch selectedView {
      case .prompt:
        PromptView(scriptManager: scriptManager)
      case .console:
        ConsoleView(scriptManager: scriptManager)
      case .models:
        ModelManagerView(scriptManager: scriptManager)
      case .settings:
        SettingsView()
      }
    } detail: {
      DetailView(fileHierarchyObject: fileHierarchy, selectedImage: $selectedImage, lastSelectedImagePath: $lastSelectedImagePath, scriptManager: scriptManager)
    }
    .background(VisualEffectBlurView(material: .headerView, blendingMode: .behindWindow))
    .navigationSplitViewStyle(.balanced)
    .onAppear {
      if let directoryPath = userSettings.outputDirectoryUrl?.path {
        fileHierarchy.rootPath = directoryPath
      }
      Task {
        await fileHierarchy.refresh()
        await loadLastSelectedImage()
        await modelManagerViewModel.loadModels()
      }
      handleScriptOnLaunch()
    }
    .onChange(of: userSettings.outputDirectoryPath) {
      if let directoryPath = userSettings.outputDirectoryUrl?.path {
        fileHierarchy.rootPath = directoryPath
      }
      Task {
        await fileHierarchy.refresh()
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .navigation) {
        HStack {
          
          if userSettings.showPythonEnvironmentControls {
            Circle()
              .fill(scriptManager.scriptState.statusColor)
              .frame(width: 10, height: 10)
              .padding(.trailing, 2)
          }
          
          if userSettings.showPythonEnvironmentControls {
            if scriptManager.scriptState == .active, let url = scriptManager.serviceUrl {
              Button(action: {
                NSWorkspace.shared.open(url)
              }) {
                Image(systemName: "network")
              }
              .padding(.vertical, 3)
            }
          }
          
          //Text(selectedView.title).font(.system(size: 15, weight: .semibold, design: .default))
          
          Picker("Options", selection: $selectedView) {
            Text("Prompt").tag(ViewManager.prompt)
            if userSettings.showDeveloperInterface {
              Text("Console").tag(ViewManager.console)
            }
            Text("Models").tag(ViewManager.models)
          }
          .pickerStyle(SegmentedPickerStyle())
          
          //Divider().padding(.leading, 6).padding(.trailing, 3)
          
          if userSettings.showPythonEnvironmentControls {
            Button(action: {
              if scriptManager.scriptState == .readyToStart {
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
            }
            .disabled(scriptManager.scriptState == .terminated)
          }
          
        }
      }
      
      ToolbarItemGroup(placement: .principal) {
        Button("Add to Queue") {
          Debug.log("Add to queue")
        }
        .buttonStyle(BorderBackgroundButtonStyle())
        .disabled(true)
        
        Button(action: {
          fetchAndSaveGeneratedImages()
        }) {
          Text("Generate")
        }
        .buttonStyle(BlueBackgroundButtonStyle())
        .disabled(
          scriptManager.scriptState != .active ||
          (scriptManager.genStatus != .idle && scriptManager.genStatus != .done) ||
          (!scriptManager.modelLoadState.allowGeneration) ||
          currentPrompt.selectedModel == nil
        )
        
        if !userHasEnteredBothRequiredFields && (!showingRequiredInputPathsView || hasDismissedRequiredInputPathsView) {
          RequiredInputPathsPulsatingButton(showingRequiredInputPathsView: $showingRequiredInputPathsView, hasDismissedRequiredInputPathsView: $hasDismissedRequiredInputPathsView)
        }
        
      }
      
      ToolbarItemGroup(placement: .automatic) {
        Spacer()
        
        if scriptManager.modelLoadState == .done && scriptManager.modelLoadTime > 0 {
          Text("\(String(format: "%.1f", scriptManager.modelLoadTime))s")
            .font(.system(size: 11, design: .monospaced))
            .padding(.trailing, 6)
        }
        
        if scriptManager.genStatus == .generating {
          Text("\(Int(scriptManager.genProgress * 100))%")
            .font(.system(.body, design: .monospaced))
        } else if scriptManager.genStatus == .finishingUp {
          Text("Saving")
            .font(.system(.body, design: .monospaced))
        } else if scriptManager.genStatus == .preparingToGenerate {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.5)
        } else if scriptManager.genStatus == .done {
          Image(systemName: "checkmark")
            .foregroundStyle(Color.green)
        }
        
        if launchStatusProgressBarValue < 0 {
          ProgressView(value: launchStatusProgressBarValue)
            .progressViewStyle(LinearProgressViewStyle())
            .frame(width: 100)
        }
        
        Button(action: {
          WindowManager.shared.showSettingsWindow()
        }) {
          Image(systemName: "gear")
        }
      }
      
    }
    .onAppear {
      if !CanvasPreview && !userHasEnteredBothRequiredFields {
        showingRequiredInputPathsView = true
      } else {
        handleScriptOnLaunch()
      }
    }
    .sheet(isPresented: $showingRequiredInputPathsView, onDismiss: {
      hasDismissedRequiredInputPathsView = true
    }) {
      RequiredInputPathsView()
    }
    .onChange(of: userSettings.webuiShellPath) {
      handleScriptOnLaunch()
    }
    .onChange(of: userSettings.stableDiffusionModelsPath) {
      handleScriptOnLaunch()
    }
    .onChange(of: scriptManager.genStatus) {
      if scriptManager.genStatus == .generating {
        imageCountToGenerate = Int(currentPrompt.batchSize * currentPrompt.batchCount)
      } else if scriptManager.genStatus == .done {
        NotificationUtility.showCompletionNotification(imageCount: imageCountToGenerate)
        Task {
          await fileHierarchy.refresh()
        }
      }
    }
    .onChange(of: scriptManager.scriptState) {
      if scriptManager.scriptState == .launching {
        launchStatusProgressBarValue = -1
      } else {
        launchStatusProgressBarValue = 100
      }
    }
  }
  
  private var userHasEnteredBothRequiredFields: Bool {
    return !userSettings.webuiShellPath.isEmpty && !userSettings.stableDiffusionModelsPath.isEmpty
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
  CommonPreviews.contentView
    .navigationTitle("")
    .frame(width: 900)
}

extension ContentView {
  func handleScriptOnLaunch() {
    if !self.hasLaunchedPythonEnvironmentOnFirstAppearance {
      Debug.log("First appearance. Starting script...")
      attemptLaunchOfPythonEnvironment()
      self.hasLaunchedPythonEnvironmentOnFirstAppearance = userHasEnteredBothRequiredFields
    }
  }
  func attemptLaunchOfPythonEnvironment() {
    if userSettings.alwaysStartPythonEnvironmentAtLaunch && userHasEnteredBothRequiredFields {
      if !CanvasPreview {
        scriptManager.run()
        Task {
          await modelManagerViewModel.loadModels()
        }
      }
    }
  }
}

let CanvasPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
