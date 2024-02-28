//
//  SidebarView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import SwiftUI
import SwiftData

extension Constants.Layout {
  struct SidebarToolbar {
    static let itemHeight: CGFloat = 20
    static let itemWidth: CGFloat = 30
    
    static let bottomBarHeight: CGFloat = 50
  }
}

struct SidebarView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  
  @Query private var sidebarItems: [SidebarItem]
  @Query private var sidebarFolders: [SidebarFolder]
  
  @Binding var selectedImage: NSImage?
  @Binding var lastSavedImageUrls: [URL]
  @AppStorage("filterToolsButtonToggled") private var filterToolsButtonToggled: Bool = false
  
  @State private var selectedItemID: UUID?
  @State private var selectedItemName: String?
  
  @State private var editingItemId: UUID? = nil
  @State private var draftTitle: String = ""
  @State private var showDeletionAlert: Bool = false
  @State private var sortingOrder: SortingOrder = .mostRecent
  
  @State private var selectedModelName: String? = nil
  
  enum SortingOrder: String {
    case mostRecent = "Most Recent"
    case leastRecent = "Least Recent"
  }
  
  var uniqueModelNames: [String] {
    Set(sidebarItems.compactMap { $0.prompt?.selectedModel?.name }).sorted()
  }
  
  var filteredItems: [SidebarItem] {
    let filtered = sidebarItems.filter {
      let isWorkspaceItem = $0.isWorkspaceItem
      return !isWorkspaceItem
    }
    if let selectedModelName = selectedModelName {
      return filtered.filter { $0.prompt?.selectedModel?.name == selectedModelName }
    } else {
      return filtered
    }
  }
  
  var sortedAndFilteredItems: [SidebarItem] {
    switch sortingOrder {
    case .mostRecent:
      return filteredItems.sorted { $0.timestamp > $1.timestamp }
    case .leastRecent:
      return filteredItems.sorted { $0.timestamp < $1.timestamp }
    }
  }
  
  var workspaceItems: [SidebarItem] {
    sidebarItems.filter {
      $0.isWorkspaceItem == true
    }
  }
  
  var sortedWorkspaceItems: [SidebarItem] {
    let regularItems = workspaceItems.filter { $0.title != "New Prompt" }
    let newPromptItems = workspaceItems.filter { $0.title == "New Prompt" }
    return regularItems + newPromptItems
  }
  
  func newFolderToData(title: String) {
    let newFolder = SidebarFolder(name: title)
    modelContext.insert(newFolder)
    sidebarViewModel.saveData(in: modelContext)
  }
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        
        FilterSortingSection(sortingOrder: $sortingOrder, selectedModelName: $selectedModelName, filterToolsButtonToggled: $filterToolsButtonToggled, uniqueModelNames: uniqueModelNames)
        
        ZStack(alignment: .bottom) {
          List(selection: $selectedItemID) {
            
            WorkspaceSection(workspaceItems: workspaceItems, selectedItemID: $selectedItemID)
            
            if let currentFolder = sidebarViewModel.currentFolder {
              Button(action: sidebarViewModel.navigateBack) {
                HStack {
                  Image(systemName: "chevron.left")
                  Text("Back")
                }
              }
              SidebarItemSection(title: currentFolder.name, items: currentFolder.items, folders: currentFolder.folders, selectedItemID: $selectedItemID)
            } else {
              SidebarItemSection(title: "Uncategorized", items: sortedAndFilteredItems, folders: sidebarFolders, selectedItemID: $selectedItemID)
            }
            /*
            UncategorizedSection(
              sortedAndFilteredItems: sortedAndFilteredItems,
              selectedItemID: $selectedItemID
            )
             */
            
            VStack {}.frame(height: Constants.Layout.SidebarToolbar.bottomBarHeight)
          }
          .listStyle(SidebarListStyle()) // .scrollIndicators(.hidden)
          .onChange(of: sidebarViewModel.itemToSave) {
            moveSavableItemFromWorkspace()
          }
          .onChange(of: sidebarViewModel.itemToDelete) {
            if sidebarViewModel.itemToDelete != nil {
              showDeletionAlert = true
            }
          }
          .onChange(of: sidebarViewModel.workspaceItemToDeleteWithoutPrompt) {
            if sidebarViewModel.workspaceItemToDeleteWithoutPrompt != nil {
              deleteWorkspaceItemWithoutPrompt()
            }
          }
          .alert(isPresented: $showDeletionAlert) {
            Alert(
              title: Text("Are you sure you want to delete this item?"),
              primaryButton: .destructive(Text("Delete")) {
                self.deleteSavedItem()
              },
              secondaryButton: .cancel() {
                sidebarViewModel.itemToDelete = nil
              }
            )
          }
          
          .onChange(of: selectedItemID) { currentItemID, newItemID in
            selectedSidebarItemChanged(from: currentItemID, to: newItemID)
          }
          .onChange(of: sidebarItems) {
            Debug.log("SidebarView.onChange of: sidebarItems")
            sidebarViewModel.allSidebarItems = sidebarItems
            sidebarViewModel.workspaceItems = workspaceItems
            sidebarViewModel.savedItems = sortedAndFilteredItems
            
            ensureNewPromptWorkspaceItemExists()
            ensureSelectedSidebarItemForSelectedItemID()
          }
          .onChange(of: sidebarViewModel.shouldCheckForNewSidebarItemToCreate) {
            if sidebarViewModel.shouldCheckForNewSidebarItemToCreate {
              ensureNewPromptWorkspaceItemExists()
              sidebarViewModel.shouldCheckForNewSidebarItemToCreate = false
            }
          }
          .onAppear {
            ensureNewPromptWorkspaceItemExists()
            ensureSelectedSidebarItemForSelectedItemID()
            sidebarViewModel.updateSavableSidebarItems(forWorkspaceItems: sortedWorkspaceItems)
          }
          
          DisplayOptionsBar()
          
        } // ZStack
      }
      .frame(width: geometry.size.width)
      .onChange(of: geometry.size.width) {
        sidebarViewModel.currentWidth = geometry.size.width-32
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        
        Button(action: {
          filterToolsButtonToggled.toggle()
        }) {
          Image(systemName: "line.3.horizontal.decrease.circle")
            .foregroundColor(filterToolsButtonToggled ? .blue : .secondary)
        }
        .frame(width: Constants.Layout.SidebarToolbar.itemWidth, height: Constants.Layout.SidebarToolbar.itemHeight)
        
        Button(action: {
          newFolderToData(title: "Untitled Folder")
        }) {
          Image(systemName: "folder.badge.plus")
        }
      }
      
    }
    .onAppear {
        preloadImages(for: sortedAndFilteredItems)
        preloadImages(for: sortedWorkspaceItems)
    }
    .onChange(of: sidebarItems) {
        preloadImages(for: sortedAndFilteredItems)
        preloadImages(for: sortedWorkspaceItems)
    }
  }
  
  private func selectedSidebarItemChanged(from currentItemID: UUID?, to newItemID: UUID?) {
    Debug.log("[SidebarView] selectedSidebarItemChanged\n  from: \(String(describing: currentItemID))\n    to: \(String(describing: newItemID))")
    
    if let isWorkspaceItem = sidebarViewModel.selectedSidebarItem?.isWorkspaceItem, isWorkspaceItem {
      sidebarViewModel.storeChangesOfSelectedSidebarItem(for: currentPrompt, in: modelContext)
    }
    
    if let newItemID = newItemID,
       let selectedItem = sidebarItems.first(where: { $0.id == newItemID }) {
      Debug.log("onChange selectItem: \(selectedItem.title)")
      sidebarViewModel.selectedSidebarItem = selectedItem
      selectedItemName = selectedItem.title
      let mapModelData = MapModelData()
      if let storedPromptModel = selectedItem.prompt {
        let newPrompt = mapModelData.fromStored(storedPromptModel: storedPromptModel)
        
        if selectedItem.title == "New Prompt" {
          newPrompt.selectedModel = nil
        }
        
        updatePromptAndSelectedImage(newPrompt: newPrompt, imageUrls: selectedItem.imageUrls)
      }
    }
    ensureSelectedSidebarItemForSelectedItemID()
  }
  
  private func ensureSelectedSidebarItemForSelectedItemID() {
    if selectedItemID == nil {
      selectNewPromptItemIfAvailable()
    }
  }
  /// Will select the "New Prompt" item from workspace items.
  private func selectNewPromptItemIfAvailable() {
    if let newPromptItemID = sidebarItems.first(where: { $0.title == "New Prompt" && $0.isWorkspaceItem == true })?.id {
      selectedItemID = newPromptItemID
    }
  }
  /// Creates a "New Prompt" item if the existing one was overwritten.
  func ensureNewPromptWorkspaceItemExists() {
    let listOfBlankNewPrompts = workspaceItems.filter { $0.title == "New Prompt" }
    
    if listOfBlankNewPrompts.isEmpty {
      _ = sidebarViewModel.createNewPromptSidebarWorkspaceItem(in: modelContext)
      sidebarViewModel.updateControlBarView = true
    }
  }
  
  private func preloadImages(for items: [SidebarItem]) {
    items.forEach { item in
      // Preload main images
      /*
      item.imageUrls.forEach { imageUrl in
        preloadImage(from: imageUrl)
      }
       */
      // Preload thumbnails
      item.imageThumbnails.forEach { imageInfo in
        preloadImage(from: imageInfo.url)
      }
      // Preload previews
      item.imagePreviews.forEach { imageInfo in
        preloadImage(from: imageInfo.url)
      }
    }
  }
  
  private func preloadImage(from url: URL) {
    DispatchQueue.global(qos: .background).async {
      guard ImageCache.shared.image(forKey: url.path) == nil, let image = NSImage(contentsOf: url) else { return }
      DispatchQueue.main.async {
        ImageCache.shared.setImage(image, forKey: url.path)
      }
    }
  }
  
  private func deleteSavedItem() {
    if let itemToDelete = sidebarViewModel.itemToDelete {
      PreviewImageProcessingManager.shared.trashPreviewAndThumbnailAssets(for: itemToDelete, in: modelContext, withSoundEffect: true)
    }
    deleteSidebarItem(sidebarViewModel.itemToDelete)
  }
  
  private func deleteWorkspaceItemWithoutPrompt() {
    deleteSidebarItem(sidebarViewModel.workspaceItemToDeleteWithoutPrompt)
  }
  
  private func deleteSidebarItem(_ sidebarItem: SidebarItem?) {
    guard let itemToDelete = sidebarItem,
          let index = sidebarItems.firstIndex(where: { $0.id == itemToDelete.id }) else { return }
    
    modelContext.delete(sidebarItems[index])
    do {
      try modelContext.save()
    } catch {
      Debug.log("Failed to delete item: \(error.localizedDescription)")
    }
    let nextSelectionIndex = determineNextSelectionIndex(afterDeleting: index)
    updateSelection(to: nextSelectionIndex)
    sidebarViewModel.itemToDelete = nil
    sidebarViewModel.workspaceItemToDeleteWithoutPrompt = nil
  }
  
  private func moveSavableItemFromWorkspace() {
    guard let itemToSave = sidebarViewModel.itemToSave else { return }
    let mapModel = MapModelData()
    itemToSave.prompt = mapModel.toStored(promptModel: currentPrompt)
    itemToSave.prompt?.isWorkspaceItem = false
    itemToSave.timestamp = Date()
    itemToSave.isWorkspaceItem = false
    selectedItemID = itemToSave.id
    sidebarViewModel.itemToSave = nil
    Debug.log("sidebarViewModel.createImageThumbnails(for: itemToSave, in: modelContext)")
    PreviewImageProcessingManager.shared.createImagePreviewsAndThumbnails(for: itemToSave, in: modelContext)
  }
  
  private func determineNextSelectionIndex(afterDeleting index: Int) -> Int? {
    if index > 0 { return index - 1 }
    else if sidebarItems.count > 1 { return 0 }
    else { return nil }
  }
  
  private func updateSelection(to index: Int?) {
    if let newIndex = index, sidebarItems.indices.contains(newIndex) {
      selectedItemID = sidebarItems[newIndex].id
    } else {
      selectedItemID = nil
    }
  }
  
  func updatePromptAndSelectedImage(newPrompt: PromptModel, imageUrls: [URL]) {
    currentPrompt.updateProperties(from: newPrompt)
    
    if let lastImageUrl = imageUrls.last, let image = NSImage(contentsOf: lastImageUrl) {
      selectedImage = image
    } else {
      selectedImage = nil
    }
  }
  
}

#Preview {
  SidebarView(
    selectedImage: .constant(MockDataController.shared.lastImage),
    lastSavedImageUrls: .constant(MockDataController.shared.mockImageUrls)
  )
  .modelContainer(MockDataController.shared.container)
  .environmentObject(PromptModel())
  .environmentObject(SidebarViewModel())
  .frame(width: 200)
  .frame(height: 600)
}
