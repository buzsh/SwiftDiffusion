//
//  ContentView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI
import SwiftData

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
  @ObservedObject var pastableService = PastableService.shared
  
  @AppStorage("hasLaunchedBeforeTest") var hasLaunchedBefore: Bool = false
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
  @State var lastSelectedImagePath: String = ""
  @State var lastSavedImageUrls: [URL] = []
  @State var imageCountToGenerate: Int = 0
  
  @State private var columnVisibility = NavigationSplitViewVisibility.all
  
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
    .navigationSplitViewStyle(.automatic)
    .background(VisualEffectBlurView(material: .headerView, blendingMode: .behindWindow))
    .onChange(of: columnVisibility) {
      sidebarModel.sidebarIsVisible = (columnVisibility != .doubleColumn)
    }
    .onChange(of: userSettings.outputDirectoryPath) {
      if let directoryPath = userSettings.outputDirectoryUrl?.path {
        fileHierarchy.rootPath = directoryPath
        Task { await fileHierarchy.refresh() }
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .navigation) {
        HStack {
          DeveloperToolbarItems(selectedView: $selectedView)
          ContentViewToolbarTitle(text: Constants.App.name)
          PasteGenerationDataButton()
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
        
        ToolbarProgressView()
          .padding(.trailing, 6)
        
        if !userHasEnteredBothRequiredFields && hasLaunchedBefore {
          RequiredInputPathsPulsatingButton(showingRequiredInputPathsView: $showingRequiredInputPathsView, hasDismissedRequiredInputPathsView: $hasDismissedRequiredInputPathsView)
        }
        
        if userSettings.showDeveloperInterface {
          ToolbarSymbolButton(title: "API Debugger", symbol: .bonjour, action: {
            WindowManager.shared.showDebugApiWindow(scriptManager: scriptManager, currentPrompt: currentPrompt, checkpointsManager: checkpointsManager, loraModelsManager: loraModelsManager)
          })
        }
        
        ToolbarSymbolButton(title: "Model Manager", symbol: .arkit, action: {
          WindowManager.shared.showCheckpointManagerWindow(scriptManager: scriptManager, currentPrompt: currentPrompt, checkpointsManager: checkpointsManager)
        })
        ToolbarSymbolButton(title: "Settings", symbol: .gear, action: {
          WindowManager.shared.showSettingsWindow()
        })
      }
      
    }
    .onAppear {
      onAppearContentViewAction()
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
      if scriptManager.genStatus == .preparingToGenerate {
        sidebarModel.currentlyGeneratingSidebarItem = sidebarModel.selectedSidebarItem
      }
      
      if scriptManager.genStatus == .generating {
        imageCountToGenerate = Int(currentPrompt.batchSize * currentPrompt.batchCount)
        
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
      sidebarModel.currentlyGeneratingSidebarItem = nil
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
  
  func checkForUpdatesIfAutomaticUpdatesAreEnabled() {
    Task {
      await updateManager.checkForUpdatesIfNeeded()
      if let currentBuildIsLatestVersion = updateManager.currentBuildIsLatestVersion,
      currentBuildIsLatestVersion == false {
        WindowManager.shared.showUpdatesWindow(updateManager: updateManager)
      }
    }
  }

}

#Preview {
  CommonPreviews.contentView
    .frame(width: 900, height: 800)
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

extension ContentView {
  func onAppearContentViewAction() {
    if hasLaunchedBefore {
      checkForUpdatesIfAutomaticUpdatesAreEnabled()
      Task {
        await pastableService.checkForPastableData()
      }
    } else {
      Delay.by(0.5) {
        showingBetaOnboardingSheetView = true
      }
    }
    
    scriptManagerObserver = ScriptManagerObserver(scriptManager: scriptManager, userSettings: userSettings, checkpointsManager: checkpointsManager, loraModelsManager: loraModelsManager, vaeModelsManager: vaeModelsManager)
    
    if let directoryPath = userSettings.outputDirectoryUrl?.path {
      fileHierarchy.rootPath = directoryPath
    }
    Task {
      await fileHierarchy.refresh()
      await loadLastSelectedImage()
    }
    
    if !CanvasPreview && !userHasEnteredBothRequiredFields && hasLaunchedBefore {
      //
    } else {
      handleScriptOnLaunch()
    }
  }
}
