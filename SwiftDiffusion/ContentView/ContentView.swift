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
  @ObservedObject var userSettings = UserSettings.shared
  
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var modelManagerViewModel: ModelManagerViewModel
  // RequiredInputPaths
  @State private var showingRequiredInputPathsView = false
  @State private var hasDismissedRequiredInputPathsView = false
  @State private var isPulsating = false
  // Console
  @ObservedObject var scriptManager: ScriptManager
  // Views
  @State private var selectedView: ViewManager = .prompt
  // Detail
  @StateObject var fileHierarchy = FileHierarchy(rootPath: "")
  @State var selectedImage: NSImage? = NSImage(named: "DiffusionPlaceholder")
  @AppStorage("lastSelectedImagePath") var lastSelectedImagePath: String = ""
  
  @State private var hasFirstAppeared = false
  
  @State var imageCountToGenerate: Int = 0
  
  @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      // Sidebar
      List {
        NavigationLink(value: ViewManager.prompt) {
          Label("New Prompt", systemImage: "text.bubble")
        }
        
        Divider()
        
        Label("Saved Prompt 1", systemImage: "photo")
        Label("Saved Prompt 2", systemImage: "photo")
        
        Divider()
        
        Label("Saved Grid 1", systemImage: "photo.on.rectangle.angled") // photo.stack, photo.on.rectangle, photo.on.rectangle.angled
        
        Divider()
        
        Label("Saved Prompts Folder", systemImage: "folder")
      }
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
      // Image, FileSelect DetailView
      DetailView(fileHierarchyObject: fileHierarchy, selectedImage: $selectedImage, lastSelectedImagePath: $lastSelectedImagePath, scriptManager: scriptManager)
    }
    .background(VisualEffectBlurView(material: .headerView, blendingMode: .behindWindow))
    .navigationSplitViewStyle(.balanced)
    .onAppear {
      if let directoryPath = userSettings.outputDirectoryUrl?.path {
        fileHierarchy.rootPath = directoryPath
      }
      
      Debug.log("[onAppear] fileHierarchy.rootPath: \(fileHierarchy.rootPath)")
      
      Task {
        await fileHierarchy.refresh()
        await loadLastSelectedImage()
      }
      if scriptManager.scriptState == .readyToStart {
        modelManagerViewModel.startObservingModelDirectories()
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
    .onChange(of: scriptManager.scriptState) {
      if scriptManager.scriptState == .active {
        Task {
          await modelManagerViewModel.loadModels()
        }
      }
      modelManagerViewModel.observeScriptManagerState(scriptManager: scriptManager)
    }
    .toolbar {
      ToolbarItemGroup(placement: .navigation) {
        HStack {
          Circle()
            .fill(scriptManager.scriptState.statusColor)
            .frame(width: 10, height: 10)
            .padding(.trailing, 2)
          
          Text(selectedView.title).font(.system(size: 15, weight: .semibold, design: .default))
          
          Divider()
            .padding(.leading, 6).padding(.trailing, 3)
          
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
          
          Spacer()
          
          if userSettings.showDebugMenu {
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
      }
      
      ToolbarItemGroup(placement: .principal) {
        Picker("Options", selection: $selectedView) {
          Text("Prompt").tag(ViewManager.prompt)
          if userSettings.showDebugMenu {
            Text("Console").tag(ViewManager.console)
          }
          Text("Models").tag(ViewManager.models)
        }
        .pickerStyle(SegmentedPickerStyle())
        
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
        .disabled(
          scriptManager.scriptState != .active ||
          (scriptManager.genStatus != .idle && scriptManager.genStatus != .done) ||
          (!scriptManager.modelLoadState.allowGeneration) ||
          currentPrompt.selectedModel == nil
        )
        
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
      }
    }
    .sheet(isPresented: $showingRequiredInputPathsView, onDismiss: {
      hasDismissedRequiredInputPathsView = true
    }) {
      RequiredInputPathsView()
    }
    .onChange(of: userSettings.webuiShellPath) {
      attemptLaunchOfPythonEnvironment()
    }
    .onChange(of: userSettings.stableDiffusionModelsPath) {
      attemptLaunchOfPythonEnvironment()
    }
    .onChange(of: scriptManager.genStatus) {
      if scriptManager.genStatus == .generating {
        imageCountToGenerate = Int(currentPrompt.batchSize * currentPrompt.batchCount)
      } else if scriptManager.genStatus == .done {
        NotificationUtility.showCompletionNotification(imageCount: imageCountToGenerate)
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

extension ModelLoadState {
  var allowGeneration: Bool {
    switch self {
    case .idle: return true
    case .done: return true
    case .failed: return true
    case .isLoading: return true
    case .launching: return true
    }
  }
}

#Preview {
  CommonPreviews.contentView
    .navigationTitle("")
}

extension ContentView {
  func handleScriptOnLaunch() {
    if !self.hasFirstAppeared {
      Debug.log("First appearance. Starting script...")
      attemptLaunchOfPythonEnvironment()
      self.hasFirstAppeared = true
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
