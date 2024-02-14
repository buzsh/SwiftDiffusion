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
  @Environment(\.modelContext) private var modelContext
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
  
  
  // Detail
  @StateObject var fileHierarchy = FileHierarchy(rootPath: "")
  @State var selectedImage: NSImage? = NSImage(named: "DiffusionPlaceholder")
  @AppStorage("lastSelectedImagePath") var lastSelectedImagePath: String = ""
  @State var lastSavedImageUrls: [URL] = []
  
  @State var imageCountToGenerate: Int = 0
  
  @State private var columnVisibility = NavigationSplitViewVisibility.all//.doubleColumn
  
  
  @Query private var sidebarItems: [SidebarItem]
  @Query private var sidebarFolders: [SidebarFolder]
  @State private var selectedItemID: UUID?
  @State private var editingItemId: UUID? = nil
  @State private var draftTitle: String = ""
  
  func saveEditedTitle(_ id: UUID, _ title: String) {
    if let index = sidebarItems.firstIndex(where: { $0.id == id }) {
      // Update the title of the found SidebarItem
      sidebarItems[index].title = title
      
      // Save the updated context
      saveData()
    }
  }
  
  func getCurrentPromptToArchive() -> (PromptModel, [URL]) {
    return (currentPrompt, lastSavedImageUrls)
  }
  
  func saveCurrentPromptToData(title: String) {
    savePromptToData(title: title, prompt: currentPrompt, imageUrls: lastSavedImageUrls)
  }
  
  func savePromptToData(title: String, prompt: PromptModel, imageUrls: [URL]) {
    let mapping = ModelDataMapping()
    let promptData = mapping.toArchive(promptModel: currentPrompt)
    let newItem = SidebarItem(title: title, timestamp: Date(), imageUrls: imageUrls, prompt: promptData)
    modelContext.insert(newItem)
    saveData()
  }
  
  func newFolderToData(title: String) {
    let newFolder = SidebarFolder(name: title)
    modelContext.insert(newFolder)
    saveData()
  }
  
  private func deleteItem(withId id: UUID) {
    guard let index = sidebarItems.firstIndex(where: { $0.id == id }) else { return }
    
    // Perform the deletion
    let itemToDelete = sidebarItems[index]
    modelContext.delete(itemToDelete)
    do {
      try modelContext.save()
    } catch {
      Debug.log("Failed to delete item: \(error.localizedDescription)")
    }
    
    // Determine the next selection
    let nextSelectionIndex = determineNextSelectionIndex(afterDeleting: index)
    
    // Update the selection
    updateSelection(to: nextSelectionIndex)
  }
  
  private func determineNextSelectionIndex(afterDeleting index: Int) -> Int? {
    if index > 0 {
      // Select the item above if available
      return index - 1
    } else if sidebarItems.count > 1 {
      // Select the next item in the list if the deleted item was the first
      return 0
    } else {
      // No items left to select
      return nil
    }
  }
  
  private func updateSelection(to index: Int?) {
    if let newIndex = index, sidebarItems.indices.contains(newIndex) {
      selectedItemID = sidebarItems[newIndex].id
    } else {
      selectedItemID = nil
    }
  }
  
  func saveData() {
    do {
      try modelContext.save()
    } catch {
      Debug.log("Error saving context: \(error)")
    }
  }
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      List(selection: $selectedItemID) {
        Section(header: Text("Folders")) {
          ForEach(sidebarFolders) { folder in
            Text(folder.name)
          }
        }
        Section(header: Text("Uncategorized")) {
          ForEach(sidebarItems) { item in
            if editingItemId == item.id {
              TextField("Title", text: $draftTitle, onCommit: {
                saveEditedTitle(item.id, draftTitle)
                editingItemId = nil
              })
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .onAppear {
                draftTitle = item.title
              }
            } else {
              Text(item.title)
                .tag(item.id)
                .gesture(TapGesture(count: 1).onEnded {
                  self.selectedItemID = item.id
                }.simultaneously(with: TapGesture(count: 2).onEnded {
                  editingItemId = item.id
                  draftTitle = item.title
                }))
            }
          }
        }
      }
      .listStyle(SidebarListStyle())
      .onChange(of: selectedItemID) { currentItem, newItemID in
        Debug.log("Selected item ID changed to: \(String(describing: newItemID))")
        if let newItemID = newItemID,
           let selectedItem = sidebarItems.first(where: { $0.id == newItemID }) {
          let modelDataMapping = ModelDataMapping()
          
          if let appPromptModel = selectedItem.prompt {
            let newPrompt = modelDataMapping.fromArchive(appPromptModel: appPromptModel)
            currentPrompt.updateProperties(from: newPrompt)
            
            if let lastImageUrl = selectedItem.imageUrls.last, let image = NSImage(contentsOf: lastImageUrl) {
              selectedImage = image
            }
          }
        }
      }
      .onAppear {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
          if event.keyCode == 51 { // 51 is the delete key code
            if let selectedItemID = selectedItemID {
              deleteItem(withId: selectedItemID)
            }
          }
          return event
        }
      }
      Spacer()
      HStack {
        Button(action: {
          newFolderToData(title: "Some Folder")
        }) {
          Image(systemName: "folder.badge.plus")
        }
        
        Button(action: {
          saveCurrentPromptToData(title: "Some Prompt")
        }) {
          Image(systemName: "plus.bubble")
        }
      }
      .frame(height: 40)
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
    .onChange(of: columnVisibility) {
      Debug.log("columnVisibility: \(columnVisibility)")
    }
    .background(VisualEffectBlurView(material: .headerView, blendingMode: .behindWindow))
    .navigationSplitViewStyle(.automatic)
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
        }
        
        if scriptManager.genStatus != .idle || scriptManager.scriptState == .launching {
          ContentProgressBar(scriptManager: scriptManager)
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
