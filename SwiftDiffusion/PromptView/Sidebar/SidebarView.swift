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
            Text(item.title)
          }
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
              
              if largePreviewsButtonToggled {
                
                if smallPreviewsButtonToggled {
                  // Conditional based on image select
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
                  }
                }
                
                VStack(alignment: .leading) {
                  Text(item.title)
                  // Show this if arkit selected
                  if modelNameButtonToggled {
                    if let prompt = item.prompt {
                      if let modelName = prompt.selectedModel?.name {
                        Text(modelName)
                          .font(.system(size: 10, weight: .light, design: .rounded))
                          .foregroundStyle(Color.secondary)
                      }
                    }
                  }
                }
                .padding(.bottom, 12)
                .padding(.top, largePreviewsButtonToggled ? 12 : 0)
                
              } else {
                
                if editingItemId == item.id {
                  HStack {
                    TextField("Title", text: $draftTitle, onCommit: {
                      saveEditedTitle(item.id, draftTitle)
                      editingItemId = nil
                      selectedItemID = item.id
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                  }
                  .onAppear {
                    draftTitle = item.title
                  }
                  .background(editingItemId == item.id ? Color.blue.opacity(0.2) : Color.clear)
                  .cornerRadius(5)
                } else {
                  HStack {
                    if smallPreviewsButtonToggled {
                      // Conditional based on image select
                      if let lastImageUrl = item.imageUrls.last {
                        AsyncImage(url: lastImageUrl) { image in
                          image
                            .resizable()
                            .aspectRatio(contentMode: .fill) // Fill the frame, maintaining aspect ratio
                            .frame(width: 40, height: 50) // Set fixed frame size
                            .clipped() // Ensure image does not extend beyond the frame
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shadow(color: .black, radius: 1, x: 0, y: 1)
                        } placeholder: {
                          ProgressView()
                        }
                      }
                    }
                    
                    VStack(alignment: .leading) {
                      Text(item.title)
                      // Show this if arkit selected
                      if modelNameButtonToggled {
                        if let prompt = item.prompt {
                          if let modelName = prompt.selectedModel?.name {
                            Text(modelName)
                              .font(.system(size: 10, weight: .light, design: .rounded))
                              .foregroundStyle(Color.secondary)
                          }
                        }
                      }
                    }
                  }
                  .tag(item.id)
                  .opacity(editingItemId == nil ? 1 : 0.5)
                  .gesture(TapGesture(count: 1).onEnded {
                    if editingItemId == nil {
                      if selectedItemID == item.id {
                        // The item is already selected, enter edit mode
                        editingItemId = item.id
                        draftTitle = item.title
                        selectedItemID = nil
                      } else {
                        // The item is not selected, select it
                        selectedItemID = item.id
                      }
                    }
                  }
                    .simultaneously(with: TapGesture(count: 2).onEnded {
                      if editingItemId == nil {
                        selectedItemID = nil
                        editingItemId = item.id
                        draftTitle = item.title
                      }
                    }))
                }
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
      .alert(isPresented: $showDeletionAlert) {
        Alert(
          title: Text("Are you sure you want to delete this item?"),
          primaryButton: .destructive(Text("Delete")) {
            self.deleteItem()
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
      .onAppear {
        ensureNewPromptWorkspaceItemExists()
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
    if !sidebarViewModel.blankNewPromptExists {
      let appPromptModel = AppPromptModel(isWorkspaceItem: true, selectedModel: nil)
      let imageUrls: [URL] = []
      let newSidebarItem = sidebarViewModel.createSidebarItemAndSaveToData(title: "New Prompt", appPrompt: appPromptModel, imageUrls: imageUrls, in: modelContext)
      return newSidebarItem
    }
    return nil
  }
  
  func ensureNewPromptWorkspaceItemExists() {
    if workspaceItems.isEmpty {
      Debug.log("No workspace items. Creating blank new prompt.")
      
      _ = createNewPromptWorkspaceSidebarItemIfNeeded()
    }
  }
  
  func updateWorkspaceItemTitle() {
    guard let selectedItemID = selectedItemID, !currentPrompt.positivePrompt.isEmpty else { return }
    if let index = sidebarViewModel.workspaceItems.firstIndex(where: { $0.id == selectedItemID && $0.prompt?.isWorkspaceItem == true }) {
      let newTitle = currentPrompt.positivePrompt
      sidebarViewModel.workspaceItems[index].title = newTitle.count > 45 ? String(newTitle.prefix(45)).appending("…") : newTitle
      sidebarViewModel.saveData(in: modelContext)
      sidebarViewModel.blankNewPromptItem = createNewPromptWorkspaceSidebarItemIfNeeded()
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
