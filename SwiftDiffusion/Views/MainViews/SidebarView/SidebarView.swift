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
  
  func newFolderToData(title: String) {
    let newFolder = SidebarFolder(name: title)
    modelContext.insert(newFolder)
    sidebarViewModel.saveData(in: modelContext)
  }
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
    let mapModel = MapModelData()
    itemToSave.prompt = mapModel.toStored(promptModel: currentPrompt)
    itemToSave.prompt?.isWorkspaceItem = false
    itemToSave.timestamp = Date()
    itemToSave.isWorkspaceItem = false
    selectedItemID = itemToSave.id
    sidebarViewModel.itemToSave = nil
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
  
  var body: some View {
    if filterToolsButtonToggled {
      List {
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
      }.frame(height: 110)
      Divider()
        .padding(.horizontal).padding(.bottom, 4)
    }
    
    ZStack(alignment: .bottom) {
      List(selection: $selectedItemID) {
        
        Section(header: Text("Workspace")) {
          ForEach(sortedWorkspaceItems) { item in
            SidebarWorkspaceItem(item: item, selectedItemID: $selectedItemID)
              .onChange(of: sortedWorkspaceItems) {
                if sidebarViewModel.newlyCreatedSidebarWorkspaceItemIdToSelect != nil {
                  selectedItemID = sidebarViewModel.newlyCreatedSidebarWorkspaceItemIdToSelect
                  sidebarViewModel.newlyCreatedSidebarWorkspaceItemIdToSelect = nil
                }
              }
          }
        }
        
        if sortedAndFilteredItems.isEmpty {
          VStack(alignment: .center) {
            Spacer(minLength: 100)
            HStack(alignment: .center) {
              Spacer()
              VStack {
                Text("Saved prompts")
                Text("will appear here!")
              }
              Spacer()
            }
            
            Spacer()
          }
          .foregroundStyle(Color.secondary)
        } else {
          
          Section(header: Text("Uncategorized")) {
            ForEach(sortedAndFilteredItems) { item in
              HStack(alignment: .center, spacing: 8) {
                if smallPreviewsButtonToggled, let lastImageUrl = item.imageUrls.last {
                  AsyncImage(url: lastImageUrl) { image in
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                      .frame(width: 50, height: 65)
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
              .padding(.vertical, 2)
              .contentShape(Rectangle())
              .onTapGesture {
                selectedItemID = item.id
              }
            }
          } // Section("Uncategorized")
          VStack {}.frame(height: Constants.Layout.SidebarToolbar.bottomBarHeight)
        }
      } // List
      .listStyle(SidebarListStyle())
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
      }
      
      DisplayOptionsBar(modelNameButtonToggled: $modelNameButtonToggled, noPreviewsItemButtonToggled: $noPreviewsItemButtonToggled, smallPreviewsButtonToggled: $smallPreviewsButtonToggled, largePreviewsButtonToggled: $largePreviewsButtonToggled)
      
    } // ZStack
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
    .onChange(of: currentPrompt.positivePrompt) {
      ensureNewPromptWorkspaceItemExists()
    }
  }
  
  private func selectedSidebarItemChanged(from currentItemID: UUID?, to newItemID: UUID?) {
    Debug.log("[SidebarView] selectedSidebarItemChanged\n  from: \(String(describing: currentItemID))\n    to: \(String(describing: newItemID))")
    
    if let isWorkspaceItem = sidebarViewModel.selectedSidebarItem?.isWorkspaceItem, isWorkspaceItem {
      sidebarViewModel.storeChangesOfSelectedSidebarItem(for: currentPrompt, in: modelContext)
    }
    
    //ensureNewPromptWorkspaceItemExists()
    
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
