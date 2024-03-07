//
//  SidebarModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import Foundation
import SwiftUI
import SwiftData

extension Constants.Sidebar {
  static let rootFolderName = "Documents"
  static let workspaceFolderName = "Workspace"
}

class SidebarModel: ObservableObject {
  var rootFolder: SidebarFolder
  var workspaceFolder: SidebarFolder
  var modelContext: ModelContext
  
  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    rootFolder = SidebarModel.ensureFolderExists(named: Constants.Sidebar.rootFolderName, isRoot: true, in: modelContext)
    workspaceFolder = SidebarModel.ensureFolderExists(named: Constants.Sidebar.workspaceFolderName, isWorkspace: true, in: modelContext)
  }
  
  static func ensureFolderExists(named name: String, isRoot: Bool = false, isWorkspace: Bool = false, in modelContext: ModelContext) -> SidebarFolder {
    let predicate = #Predicate<SidebarFolder> { $0.name == name && $0.isRoot == isRoot && $0.isWorkspace == isWorkspace }
    let descriptor = FetchDescriptor<SidebarFolder>(predicate: predicate)
    
    let folders: [SidebarFolder]
    do {
      folders = try modelContext.fetch(descriptor)
    } catch {
      Debug.log("Failed to fetch folders: \(error)")
      folders = []
    }
    if let folder = folders.first {
      return folder
    } else {
      let newFolder = SidebarFolder(name: name, timestamp: Date(), isRoot: isRoot, isWorkspace: isWorkspace)
      modelContext.insert(newFolder)
      try? modelContext.save()
      return newFolder
    }
  }
  
  @Published var selectedItemID: UUID? = nil
  @Published var selectedSidebarItem: SidebarItem? = nil
  @Published var currentFolder: SidebarFolder? = nil
  @Published var currentlyGeneratingSidebarItem: SidebarItem? = nil
  
  /// SidebarItems that have been generated and can now be stored to the user's library.
  @Published var storableSidebarItems: [SidebarItem] = []
  
  @Published var modelNameButtonToggled: Bool = true
  @Published var noPreviewsItemButtonToggled: Bool = false
  @Published var smallPreviewsButtonToggled: Bool = true
  @Published var largePreviewsButtonToggled: Bool = false
  @Published var currentWidth: CGFloat = 240
  @Published var widthOffset: CGFloat = 32 // 50
  
  @Published var applyCustomLeadingInsets = false
  // TODO: Do we need?
  @Published var updateControlBarView: Bool = false
  
  @Published var queueWorkspaceItemForDeletion: SidebarItem? = nil
  @Published var queueStoredSidebarItemForDeletion: SidebarItem? = nil
  
  @Published var queueMovableSidebarItemID: UUID? = nil
  @Published var queueDestinationFolderID: UUID? = nil
  @Published var beginMovableSidebarItemQueue: Bool = false
  
  @Published var workspaceItemHasJustBeenRemoved: Bool = false
  @Published var sidebarItemHasJustBeenDeleted: Bool = false
  @Published var sidebarFolderHasJustBeenDeleted: Bool = false
  
  @Published var sidebarIsVisible: Bool = true
  
  var disablePromptView: Bool {
    selectedSidebarItemIsCurrentlyGenerating() || (workspaceFolderContainsSelectedSidebarItem() == false)
  }
  
  enum SortingOrder: String {
    case mostRecent = "Most Recent"
    case leastRecent = "Least Recent"
  }
  
  func setCurrentFolder(to folder: SidebarFolder?, selectItem: Bool = false) {
    if let folder = folder, folder != workspaceFolder  {
      currentFolder = folder
      if selectItem {
        selectedItemID = folder.id
      }
    }
  }
  
  func setSelectedSidebarItem(to sidebarItem: SidebarItem?) {
    selectedItemID = sidebarItem?.id
  }
  
  func moveSidebarItem(withId sidebarItemId: UUID, toFolderWithId folderId: UUID) {
    queueMovableSidebarItemID = sidebarItemId
    queueDestinationFolderID = folderId
    beginMovableSidebarItemQueue = true
  }
  
  func addToStorableSidebarItems(sidebarItem: SidebarItem, withImageUrls imageUrls: [URL]) {
    sidebarItem.imageUrls = imageUrls
    storableSidebarItems.append(sidebarItem)
  }
  
  @MainActor
  func moveStorableSidebarItemToFolder(sidebarItem: SidebarItem, withPrompt prompt: PromptModel) {
    storableSidebarItems.removeAll(where: { $0 == sidebarItem })
    let mapModelData = MapModelData()
    sidebarItem.prompt = mapModelData.toStored(promptModel: prompt)
    sidebarItem.timestamp = Date()
    currentFolder?.add(item: sidebarItem)
    workspaceFolder.remove(item: sidebarItem)
    PreviewImageProcessingManager.shared.createImagePreviewsAndThumbnails(for: sidebarItem, in: modelContext)
    saveData(in: modelContext)
  }
  
  func deleteFromWorkspace(sidebarItem: SidebarItem, in modelContext: ModelContext) {
    selectNextClosestSidebarItemIfApplicable(sortedItems: sortedWorkspaceFolderItems, sortingOrder: .mostRecent)
    withAnimation {
      workspaceFolder.remove(item: sidebarItem)
    }
    saveData(in: modelContext)
  }
  
  func selectNewWorkspaceItemIfApplicable() {
    let sortedItems = sortedWorkspaceFolderItems
    guard !sortedItems.isEmpty else {
      setSelectedSidebarItem(to: nil)
      return
    }
    if let currentItem = selectedSidebarItem,
       let currentIndex = sortedItems.firstIndex(of: currentItem) {
      if currentIndex > 0 {
        setSelectedSidebarItem(to: sortedItems[currentIndex - 1])
      }
      else if sortedItems.count > 1 {
        setSelectedSidebarItem(to: sortedItems[min(currentIndex + 1, sortedItems.count - 1)])
      }
      else {
        setSelectedSidebarItem(to: nil)
      }
    } else {
      setSelectedSidebarItem(to: sortedItems.first)
    }
  }
  
  
  func deleteSelectedSidebarItemFromStorage(in modelContext: ModelContext) {
    if let selectedSidebarItem = selectedSidebarItem {
      selectNextClosestSidebarItemIfApplicable(sortedItems: sortedCurrentFolderItems, sortingOrder: .leastRecent)
      PreviewImageProcessingManager.shared.trashPreviewAndThumbnailAssets(for: selectedSidebarItem, in: modelContext, withSoundEffect: true)
      if let currentFolder = currentFolder {
        Debug.log("[Delete] item: \(selectedSidebarItem.title), from currentFolder: \(currentFolder.name)")
      }
      currentFolder?.remove(item: selectedSidebarItem)
      saveData(in: modelContext)
      sidebarItemHasJustBeenDeleted = true
    }
  }

  func workspaceFolderContainsSelectedSidebarItem() -> Bool {
    workspaceFolderContains(sidebarItem: selectedSidebarItem)
  }
  
  func selectedSidebarItemIsCurrentlyGenerating() -> Bool {
    selectedSidebarItem == currentlyGeneratingSidebarItem
  }
  
  func workspaceFolderContains(sidebarItem: SidebarItem?) -> Bool {
    if workspaceFolder.items.contains(where: { $0.id == sidebarItem?.id }) {
      return true
    }
    return false
  }
  
  func selectedItemIsStorableItem() -> Bool {
    if let selectedSidebarItem = selectedSidebarItem, storableSidebarItems.contains(where: { $0 == selectedSidebarItem }) {
      return true
    }
    return false
  }
  
  /// Iterates through workspace items and populates savableSidebarItems with prompts that have previously generated media URLs associated with them.
  func updateStorableSidebarItemsInWorkspace() {
    for sidebarItem in workspaceFolder.items {
      if sidebarItem.imageUrls.isEmpty == false {
        storableSidebarItems.append(sidebarItem)
      }
    }
  }
}


extension SidebarModel {
  @MainActor func storeChangesOfSelectedSidebarItem(with prompt: PromptModel, in modelContext: ModelContext) {
    if let selectedSidebarItem = selectedSidebarItem {
      storeChanges(of: selectedSidebarItem, with: prompt, in: modelContext)
    }
  }
  
  @MainActor func storeChanges(of sidebarItem: SidebarItem, with prompt: PromptModel, in modelContext: ModelContext) {
    //shouldCheckForNewSidebarItemToCreate = true
    if workspaceFolderContains(sidebarItem: sidebarItem) {
      let mapModelData = MapModelData()
      let updatedPrompt = mapModelData.toStored(promptModel: prompt)
      
      if !selectedSidebarItemTitle(hasEqualTitleTo: updatedPrompt) && !prompt.positivePrompt.isEmpty {
        if let newTitle = updatedPrompt?.positivePrompt {
          selectedSidebarItem?.title = newTitle.count > Constants.Sidebar.titleLength ? String(newTitle.prefix(Constants.Sidebar.titleLength)).appending("…") : newTitle
        }
      }
      
      selectedSidebarItem?.prompt = updatedPrompt
      //selectedSidebarItem?.timestamp = Date()
      saveData(in: modelContext)
    }
  }
}

extension SidebarModel {
  func findSidebarItem(by id: UUID?, in sidebarFolders: [SidebarFolder]) -> SidebarItem? {
    guard let id = id else { return nil }
    for folder in sidebarFolders {
      if let foundItem = folder.items.first(where: { $0.id == id }) {
        return foundItem
      }
    }
    return nil
  }
}

extension SidebarModel {
  func saveData(in model: ModelContext) {
    do {
      try model.save()
      Debug.log("[DD] Data successfully saved")
    } catch {
      Debug.log("[DD] Error saving context: \(error)")
    }
  }
}
