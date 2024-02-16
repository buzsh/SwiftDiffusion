//
//  SidebarView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import SwiftUI
import SwiftData

enum KeyCodes {
  case deleteKey
  
  var code: UInt16 {
    switch self {
    case .deleteKey: return 51
    }
  }
}

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
  
  @AppStorage("modelNameButtonToggled") private var modelNameButtonToggled: Bool = true
  @AppStorage("noPreviewsButtonToggled") private var noPreviewsItemButtonToggled: Bool = false
  @AppStorage("smallPreviewsButtonToggled") private var smallPreviewsButtonToggled: Bool = true
  @AppStorage("largePreviewsButtonToggled") private var largePreviewsButtonToggled: Bool = false
  
  @AppStorage("filterToolsButtonToggled") private var filterToolsButtonToggled: Bool = false
  
  //@AppStorage("selectedSidebarItemIDString") private var selectedItemIDString: String?
  @State private var selectedItemID: UUID?
  
  @State private var selectedItemName: String?
  @State private var editingItemId: UUID? = nil
  @State private var draftTitle: String = ""
  
  @State private var showDeletionAlert: Bool = false
  
  @State private var sortingOrder: SortingOrder = .mostRecent
  
  @State private var lastSelectedSidebarItem: SidebarItem?
  
  enum SortingOrder: String {
    case mostRecent = "Most Recent"
    case leastRecent = "Least Recent"
  }
  
  @State private var selectedModelName: String? = nil
  
  var uniqueModelNames: [String] {
    Set(sidebarItems.compactMap { $0.prompt?.selectedModel?.name }).sorted()
  }
  
  func saveEditedTitle(_ id: UUID, _ title: String) {
    if let index = sidebarItems.firstIndex(where: { $0.id == id }) {
      sidebarItems[index].title = title
      sidebarViewModel.saveData(in: modelContext)
    }
  }
  
  func getCurrentPromptToArchive() -> (PromptModel, [URL]) {
    return (currentPrompt, lastSavedImageUrls)
  }
  
  func saveCurrentPromptToData(withTitle title: String) {
    sidebarViewModel.savePromptToData(title: title, prompt: currentPrompt, imageUrls: lastSavedImageUrls, in: modelContext)
  }
  
  func saveCurrentPromptToData() {
    var promptTitle = "My Prompt"
    if !currentPrompt.positivePrompt.isEmpty {
      promptTitle = currentPrompt.positivePrompt.prefix(35).appending("…")
    } else if let selectedModel = currentPrompt.selectedModel {
      promptTitle = selectedModel.name
    }
    sidebarViewModel.savePromptToData(title: promptTitle, prompt: currentPrompt, imageUrls: lastSavedImageUrls, in: modelContext)
  }
  
  func newFolderToData(title: String) {
    let newFolder = SidebarFolder(name: title)
    modelContext.insert(newFolder)
    sidebarViewModel.saveData(in: modelContext)
  }
  
  /*
  private func deleteItem() {
    guard let itemToDelete = sidebarViewModel.itemToDelete,
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
  }
   */
  
  private func deleteSavedItem() {
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
    let mapModel = ModelDataMapping()
    
    itemToSave.prompt = mapModel.toArchive(promptModel: currentPrompt)
    itemToSave.timestamp = Date()
    itemToSave.prompt?.isWorkspaceItem = false
    selectedItemID = itemToSave.id
    sidebarViewModel.itemToSave = nil
  }
  
  private func determineNextSelectionIndex(afterDeleting index: Int) -> Int? {
    if index > 0 {
      return index - 1  // Select the item above if available
    } else if sidebarItems.count > 1 {
      // Select the next item in the list if the deleted item was the first
      return 0
    } else {
      return nil // No items left to select
    }
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
    }
  }
  
  var filteredItems: [SidebarItem] {
    let filtered = sidebarItems.filter {
      let isWorkspaceItem = $0.prompt?.isWorkspaceItem ?? false
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
      $0.prompt?.isWorkspaceItem == true
    }
  }
  
  var body: some View {
    ZStack(alignment: .bottom) {
      List(selection: $selectedItemID) {
        
        Section(header: Text("Workspace")) {
          ForEach(workspaceItems) { item in
            HStack {
              Text(item.title)
              if item.title == "New Prompt" {
                Spacer()
                Image(systemName: "plus.circle")
              }
            }
          }
        }
        .onChange(of: currentPrompt.positivePrompt) {
          saveChangesToCurrentlySelectedWorkspaceItem()
        }
        .onChange(of: currentPrompt.negativePrompt) {
          saveChangesToCurrentlySelectedWorkspaceItem()
        }
        
        
        if sortedAndFilteredItems.isEmpty {
          Spacer()
          
          HStack(alignment: .center) {
            Text("Saved prompts will appear here!")
              .foregroundStyle(Color.secondary)
              .multilineTextAlignment(.center)
          }
          Spacer()
          
        } else {
          
          if filterToolsButtonToggled {
            
            Section(header: Text("Sorting")) {
              Menu(sortingOrder.rawValue) {
                Button("Most Recent") {
                  sortingOrder = .mostRecent
                }
                Button("Least Recent") {
                  sortingOrder = .leastRecent
                }
              }
            }
            
            Section(header: Text("Filters")) {
              Menu(selectedModelName ?? "Filter by Model") {
                Button("Show All") {
                  selectedModelName = nil
                }
                Divider()
                ForEach(uniqueModelNames, id: \.self) { modelName in
                  Button(modelName) {
                    selectedModelName = modelName
                  }
                }
              }
            }
          }
          
          Section(header: Text("Uncategorized")) {
            ForEach(sortedAndFilteredItems) { item in
              HStack(alignment: .center, spacing: 8) {
                if smallPreviewsButtonToggled, let lastImageUrl = item.imageUrls.last {
                  AsyncImage(url: lastImageUrl) { image in
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                      .frame(width: 40, height: 50)
                      .clipped()
                      .clipShape(RoundedRectangle(cornerRadius: 8))
                      .shadow(color: .black, radius: 1, x: 0, y: 1)
                  } placeholder: {
                    ProgressView()
                  }
                }
                
                VStack(alignment: .leading) {
                  if largePreviewsButtonToggled {
                    if let lastImageUrl = item.imageUrls.last {
                      AsyncImage(url: lastImageUrl) { image in
                        image
                          .resizable()
                          .scaledToFit()
                          .clipShape(RoundedRectangle(cornerRadius: 12))
                          .shadow(color: .black, radius: 1, x: 0, y: 1)
                      } placeholder: {
                        ProgressView()
                      }
                      .padding(.bottom, 8)
                    }
                  }
                  
                  Text(item.title)
                    .lineLimit(modelNameButtonToggled ? 1 : 2)
                  
                  if modelNameButtonToggled, let modelName = item.prompt?.selectedModel?.name {
                    Text(modelName)
                      .font(.system(size: 10, weight: .light, design: .monospaced))
                      .foregroundStyle(Color.secondary)
                      .padding(.top, 1)
                  }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
              }
              .padding(.vertical, 4)
              .contentShape(Rectangle())
              .onTapGesture {
                selectedItemID = item.id
              }
            }
          }//Section("Uncategorized")
          VStack {}.frame(height: Constants.Layout.SidebarToolbar.bottomBarHeight)
        }
      }// List
      //.scrollIndicators(.hidden)
      .onChange(of: sidebarViewModel.itemToSave) {
        if sidebarViewModel.itemToSave != nil {
          moveSavableItemFromWorkspace()
        }
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
      .listStyle(SidebarListStyle())
      .onChange(of: selectedItemID) { currentItem, newItemID in
        Debug.log("Selected item ID changed to: \(String(describing: newItemID))")
        if let newItemID = newItemID,
           let selectedItem = sidebarItems.first(where: { $0.id == newItemID }) {
          Debug.log("onChange selectItem: \(selectedItem.title)")
          sidebarViewModel.selectedSidebarItem = selectedItem
          selectedItemName = selectedItem.title
          let modelDataMapping = ModelDataMapping()
          if let appPromptModel = selectedItem.prompt {
            let newPrompt = modelDataMapping.fromArchive(appPromptModel: appPromptModel)
            updatePromptAndSelectedImage(newPrompt: newPrompt, imageUrls: selectedItem.imageUrls)
          }
        }
        ensureSelectedSidebarItemForSelectedItemID()
      }
      .onChange(of: sidebarItems) {
        Debug.log("SidebarView.onChange of: sidebarItems")
        // TODO: Refactor data flow; ie. have List load data from these:
        sidebarViewModel.allSidebarItems = sidebarItems
        sidebarViewModel.workspaceItems = workspaceItems
        sidebarViewModel.savedItems = sortedAndFilteredItems
        
        ensureNewPromptWorkspaceItemExists()
        ensureSelectedSidebarItemForSelectedItemID()
      }
      .onChange(of: sidebarViewModel.workspaceItems) {
        Debug.log("SidebarView.onChange of: sidebarViewModel.workspaceItems")
      }
      .onChange(of: currentPrompt.positivePrompt) {
        if !currentPrompt.positivePrompt.isEmpty {
          updateWorkspaceItemTitle()
        }
      }
      .onAppear {
        ensureNewPromptWorkspaceItemExists()
        ensureSelectedSidebarItemForSelectedItemID()
        
        saveWorkspaceItemsOnInterval()
      }
      
      DisplayOptionsBar(modelNameButtonToggled: $modelNameButtonToggled, noPreviewsItemButtonToggled: $noPreviewsItemButtonToggled, smallPreviewsButtonToggled: $smallPreviewsButtonToggled, largePreviewsButtonToggled: $largePreviewsButtonToggled)
      
    }//ZStack
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        Button(action: {
          filterToolsButtonToggled.toggle()
        }) {
          Image(systemName: "line.3.horizontal.decrease.circle")
            .foregroundColor(filterToolsButtonToggled ? .blue : .secondary)
        }
        .frame(width: Constants.Layout.SidebarToolbar.itemWidth, height: Constants.Layout.SidebarToolbar.itemHeight)
      }
    }
  }
  
  private func ensureSelectedSidebarItemForSelectedItemID() {
    if selectedItemID == nil {
      selectNewPromptItemIfAvailable()
    }
  }
  
  private func selectNewPromptItemIfAvailable() {
    if let newPromptItemID = sidebarItems.first(where: { $0.title == "New Prompt" && $0.prompt?.isWorkspaceItem == true })?.id {
      selectedItemID = newPromptItemID
    }
  }
  
  func createNewPromptWorkspaceSidebarItemIfNeeded() -> SidebarItem? {
    let listOfBlankNewPrompts = sidebarItems.filter { $0.prompt?.isWorkspaceItem == true && $0.title == "New Prompt" }
    
    if listOfBlankNewPrompts.isEmpty {
      let appPromptModel = AppPromptModel(isWorkspaceItem: true, selectedModel: nil)
      let imageUrls: [URL] = []
      let newSidebarItem = sidebarViewModel.createSidebarItemAndSaveToData(title: "New Prompt", appPrompt: appPromptModel, imageUrls: imageUrls, in: modelContext)
      return newSidebarItem
    }
    return nil
  }
  
  func ensureNewPromptWorkspaceItemExists() {
    _ = createNewPromptWorkspaceSidebarItemIfNeeded()
  }
  /// Returns the currently selected SidebarItem if has property`.isWorkspaceItem == true`. Else, returns `nil`.
  var selectedWorkspaceItem: SidebarItem? {
    if let workspaceItem = sidebarViewModel.selectedSidebarItem, workspaceItem.prompt?.isWorkspaceItem == true {
      return workspaceItem
    }
    return nil
  }
  
  func updateWorkspaceItemTitle() {
    guard let workspaceItem = sidebarViewModel.selectedSidebarItem, workspaceItem.prompt?.isWorkspaceItem == true else {
      return
    }
    
    let newTitle = currentPrompt.positivePrompt
    workspaceItem.title = newTitle.count > 45 ? String(newTitle.prefix(45)).appending("…") : newTitle
    
    sidebarViewModel.selectedSidebarItem?.title = newTitle
    
    ensureNewPromptWorkspaceItemExists()
  }
  
  
  func saveChangesToWorkspaceItem(for sidebarItem: SidebarItem) {
    let mapData = ModelDataMapping()
    let prompt = currentPrompt
    prompt.isWorkspaceItem = false
    sidebarItem.prompt = mapData.toArchive(promptModel: currentPrompt)
  }
  
  func saveChangesToCurrentlySelectedWorkspaceItem() {
    if let selectedItem = selectedWorkspaceItem {
      saveChangesToWorkspaceItem(for: selectedItem)
    }
  }
  
  func saveWorkspaceItemsOnInterval() {
    Delay.repeatEvery(3) {
      saveChangesToCurrentlySelectedWorkspaceItem()
    }
  }
  /// If the last selected item was a workspace item, save changes made to said workspace item..
  func saveChangesToLastSelectedWorkplaceItem() {
    if let workspaceItem = lastSelectedSidebarItem, workspaceItem.prompt?.isWorkspaceItem == true {
      saveChangesToWorkspaceItem(for: workspaceItem)
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



import SwiftUI
import AppKit

struct VisualEffectView: NSViewRepresentable {
  var material: NSVisualEffectView.Material
  var blendingMode: NSVisualEffectView.BlendingMode
  
  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
    return view
  }
  
  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
  }
}
