//
//  ContentView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI
import SwiftData

extension Constants.Layout {
  static let verticalPadding: CGFloat = 8
}

enum ViewManager {
  case prompt, console, split
  
  var title: String {
    switch self {
    case .prompt: return "Prompt"
    case .console: return "Console"
    case .split: return "Split"
    }
  }
}

extension ViewManager: Hashable, Identifiable {
  var id: Self { self }
}

struct ContentView: View {
  @Environment(\.modelContext) var modelContext
  @EnvironmentObject var updateManager: UpdateManager
  @EnvironmentObject var sidebarModel: SidebarModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var loraModelsManager: ModelManager<LoraModel>
  @EnvironmentObject var vaeModelsManager: ModelManager<VaeModel>
  
  @ObservedObject var userSettings = UserSettings.shared
  @ObservedObject var scriptManager = ScriptManager.shared
  
  @State private var scriptManagerObserver: ScriptManagerObserver?
  
  @AppStorage("hasLaunchedBeforeTest4") var hasLaunchedBefore: Bool = false
  @State private var showingBetaOnboardingSheetView: Bool = false
  
  // RequiredInputPaths
  @State private var showingRequiredInputPathsView = false
  @State private var hasDismissedRequiredInputPathsView = false
  @State private var isPulsating = false
  
  // TabView
  @State private var selectedView: ViewManager = .prompt
  @State private var hasLaunchedPythonEnvironmentOnFirstAppearance = false
  
  // Detail
  @StateObject var fileHierarchy = FileHierarchy(rootPath: "")
  @State var selectedImage: NSImage? = nil
  @AppStorage("lastSelectedImagePath") var lastSelectedImagePath: String = ""
  @State var lastSavedImageUrls: [URL] = []
  
  @State var imageCountToGenerate: Int = 0
  
  @State private var columnVisibility = NavigationSplitViewVisibility.all // .doubleColumn (hide by default)
  
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      Sidebar(selectedImage: $selectedImage, lastSavedImageUrls: $lastSavedImageUrls)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 340)
      
    } content: {
      switch selectedView {
      case .prompt:
        PromptView()
      case .console:
        ConsoleView()
      case .split:
        PromptView(isRightPaneVisible: true)
      }
      
    } detail: {
      DetailView(fileHierarchyObject: fileHierarchy, selectedImage: $selectedImage, lastSelectedImagePath: $lastSelectedImagePath)
    }
    .onChange(of: columnVisibility) {
      Debug.log("columnVisibility: \(columnVisibility)")
      sidebarModel.sidebarIsVisible = (columnVisibility != .doubleColumn)
    }
    .background(VisualEffectBlurView(material: .headerView, blendingMode: .behindWindow))
    .navigationSplitViewStyle(.automatic)
    .onAppear {
      scriptManagerObserver = ScriptManagerObserver(scriptManager: scriptManager, userSettings: userSettings, checkpointsManager: checkpointsManager, loraModelsManager: loraModelsManager, vaeModelsManager: vaeModelsManager)
      
      if let directoryPath = userSettings.outputDirectoryUrl?.path {
        fileHierarchy.rootPath = directoryPath
      }
      Task {
        await fileHierarchy.refresh()
        await loadLastSelectedImage()
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
          
          if userSettings.showPythonEnvironmentControls && userSettings.launchWebUiAlongsideScriptLaunch {
            if scriptManager.scriptState == .active, let url = scriptManager.serviceUrl {
              Button(action: {
                NSWorkspace.shared.open(url)
              }) {
                Image(systemName: "network")
              }
              .padding(.vertical, 3)
            }
          }
          
          if userSettings.showDeveloperInterface {
            Picker("Options", selection: $selectedView) {
              Text("Prompt").tag(ViewManager.prompt)
              Text("Console").tag(ViewManager.console)
              Text("Split").tag(ViewManager.split)
            }
            .pickerStyle(SegmentedPickerStyle())
          } else {
            Text("SwiftDiffusion").font(.system(size: 15, weight: .semibold, design: .default))
          }
          
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
        BlueButton(title: "Generate") {
          fetchAndSaveGeneratedImages()
        }
        // TODO: queue generation instead
        .disabled(
          scriptManager.scriptState != .active ||
          (scriptManager.genStatus != .idle && scriptManager.genStatus != .done) ||
          currentPrompt.selectedModel == nil
        )
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
        }
        
        if scriptManager.genStatus != .idle || scriptManager.scriptState == .launching {
          ContentProgressBar(scriptManager: scriptManager)
        }
        
        if !userHasEnteredBothRequiredFields && hasLaunchedBefore {
          RequiredInputPathsPulsatingButton(showingRequiredInputPathsView: $showingRequiredInputPathsView, hasDismissedRequiredInputPathsView: $hasDismissedRequiredInputPathsView)
        }
        
        if userSettings.showDeveloperInterface {
          Button(action: {
            WindowManager.shared.showDebugApiWindow(scriptManager: scriptManager, currentPrompt: currentPrompt, checkpointsManager: checkpointsManager, loraModelsManager: loraModelsManager)
          }) {
            Image(systemName: "bonjour") // key.icloud, bolt.horizontal.icloud
          }
        }
        
        Button(action: {
          WindowManager.shared.showCheckpointManagerWindow(scriptManager: scriptManager, currentPrompt: currentPrompt, checkpointsManager: checkpointsManager)
        }) {
          Image(systemName: "arkit")
        }
        
        Button(action: {
          WindowManager.shared.showSettingsWindow()
        }) {
          Image(systemName: "gear")
        }
      }
      
    }
    .onAppear {
      if !CanvasPreview && !userHasEnteredBothRequiredFields && hasLaunchedBefore {
        //showingRequiredInputPathsView = true
      } else {
        handleScriptOnLaunch()
      }
      
      if hasLaunchedBefore == false {
        Delay.by(0.5) {
          showingBetaOnboardingSheetView = true
        }
      }
    }
    .sheet(isPresented: $showingBetaOnboardingSheetView, onDismiss: {
      showingBetaOnboardingSheetView = false
      hasLaunchedBefore = true
    }) {
      BetaOnboardingView()
    }
    .sheet(isPresented: $showingRequiredInputPathsView, onDismiss: {
      hasDismissedRequiredInputPathsView = true
    }) {
      RequiredInputPathsView()
    }
    .onChange(of: userSettings.automaticDirectoryPath) {
      handleScriptOnLaunch()
    }
    .onChange(of: userSettings.webuiShellPath) {
      handleScriptOnLaunch()
    }
    .onChange(of: scriptManager.genStatus) {
      if scriptManager.genStatus == .generating {
        imageCountToGenerate = Int(currentPrompt.batchSize * currentPrompt.batchCount)
        sidebarModel.currentlyGeneratingSidebarItem = sidebarModel.selectedSidebarItem
        
      } else if scriptManager.genStatus == .done {
        imagesDidGenerateSuccessfully()
        
      }
    }
    .onChange(of: scriptManager.modelLoadState) {
      if scriptManager.modelLoadState == .failed && scriptManager.genStatus == .preparingToGenerate {
        scriptManager.genStatus = .idle
      }
    }
    
  }
  
  func imagesDidGenerateSuccessfully() {
    NotificationUtility.showCompletionNotification(imageCount: imageCountToGenerate)
    
    if let storableSidebarItem = sidebarModel.currentlyGeneratingSidebarItem {
      sidebarModel.addToStorableSidebarItems(sidebarItem: storableSidebarItem, withImageUrls: lastSavedImageUrls)
    }
    
    Task {
      await fileHierarchy.refresh()
    }
  }
  
  private var userHasEnteredBothRequiredFields: Bool {
    return !userSettings.automaticDirectoryPath.isEmpty && !userSettings.webuiShellPath.isEmpty
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
      }
    }
  }
}

let CanvasPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
