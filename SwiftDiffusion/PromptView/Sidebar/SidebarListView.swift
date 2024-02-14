//
//  SidebarListView.swift
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

struct SidebarListView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  
  @Query private var sidebarItems: [SidebarItem]
  @Query private var sidebarFolders: [SidebarFolder]
  
  @Binding var selectedImage: NSImage?
  @Binding var lastSavedImageUrls: [URL]
  
  @State private var selectedItemID: UUID?
  @State private var selectedItemName: String?
  @State private var editingItemId: UUID? = nil
  @State private var draftTitle: String = ""
  
  @State private var showDeletionAlert: Bool = false
  @State private var itemToDelete: SidebarItem?
  
  func saveEditedTitle(_ id: UUID, _ title: String) {
    if let index = sidebarItems.firstIndex(where: { $0.id == id }) {
      sidebarItems[index].title = title
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
    Debug.log("savePromptToData prompt.SdModel: \(String(describing: prompt.selectedModel?.sdModel?.title))")
    modelContext.insert(newItem)
    saveData()
  }
  
  func newFolderToData(title: String) {
    let newFolder = SidebarFolder(name: title)
    modelContext.insert(newFolder)
    saveData()
  }
  
  private func promptForDeletion(item: SidebarItem) {
    itemToDelete = item
    showDeletionAlert = true
  }
  
  private func deleteItem() {
    guard let itemToDelete = itemToDelete,
          let index = sidebarItems.firstIndex(where: { $0.id == itemToDelete.id }) else { return }
    modelContext.delete(sidebarItems[index])
    do {
      try modelContext.save()
    } catch {
      Debug.log("Failed to delete item: \(error.localizedDescription)")
    }
    let nextSelectionIndex = determineNextSelectionIndex(afterDeleting: index)
    updateSelection(to: nextSelectionIndex)
    self.itemToDelete = nil
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
  
  func saveData() {
    do {
      try modelContext.save()
    } catch {
      Debug.log("Error saving context: \(error)")
    }
  }
  
  func updatePromptAndSelectedImage(newPrompt: PromptModel, imageUrls: [URL]) {
    currentPrompt.updateProperties(from: newPrompt)
    
    if let lastImageUrl = imageUrls.last, let image = NSImage(contentsOf: lastImageUrl) {
      selectedImage = image
    }
  }
  
  var body: some View {
    List(selection: $selectedItemID) {
      Section(header: Text("Unsaved")) {
        /*
        ForEach(sidebarItems) { item in
          HStack {
            Text(item.title)
          }
        }
         */
        Text("New Prompt")
      }
      Section(header: Text("Folders")) {
        ForEach(sidebarFolders) { folder in
          HStack {
            Image(systemName: "folder")
            Text(folder.name)
          }
        }
      }
      Section(header: Text("Uncategorized")) {
        ForEach(sidebarItems) { item in
          if editingItemId == item.id {
            TextField("Title", text: $draftTitle, onCommit: {
              saveEditedTitle(item.id, draftTitle)
              editingItemId = nil
              // Optionally reselect the item here if desired
              // selectedItemID = item.id
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onAppear {
              draftTitle = item.title
            }
          } else {
            Text(item.title)
              .tag(item.id)
              .gesture(TapGesture(count: 1).onEnded {
                // Prevent changing the selected item if an item is being edited
                if self.editingItemId == nil {
                  self.selectedItemID = item.id
                }
              }.simultaneously(with: TapGesture(count: 2).onEnded {
                // Prevent double-tap from affecting selection if already editing
                if self.editingItemId == nil {
                  self.selectedItemID = nil // Clear selection here
                  editingItemId = item.id
                  draftTitle = item.title
                }
              }))
          }
        }
      }

      Spacer()
    }
    .alert(isPresented: $showDeletionAlert) {
      Alert(
        title: Text("Are you sure you want to delete this item?"),
        primaryButton: .destructive(Text("Delete")) {
          self.deleteItem()
        },
        secondaryButton: .cancel() {
          self.itemToDelete = nil
        }
      )
    }
    .listStyle(SidebarListStyle())
    .onChange(of: selectedItemID) { currentItem, newItemID in
      Debug.log("Selected item ID changed to: \(String(describing: newItemID))")
      if let newItemID = newItemID,
         let selectedItem = sidebarItems.first(where: { $0.id == newItemID }) {
        Debug.log("onChange selectItem: \(selectedItem.title)")
        selectedItemName = selectedItem.title
        let modelDataMapping = ModelDataMapping()
        if let appPromptModel = selectedItem.prompt {
          let newPrompt = modelDataMapping.fromArchive(appPromptModel: appPromptModel)
          updatePromptAndSelectedImage(newPrompt: newPrompt, imageUrls: selectedItem.imageUrls)
        }
      }
    }
    .onAppear {
      NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
        if event.keyCode == KeyCodes.deleteKey.code {
          if self.editingItemId == nil,
             let selectedItemID = self.selectedItemID,
             let itemToDelete = self.sidebarItems.first(where: { $0.id == selectedItemID }) {
            self.promptForDeletion(item: itemToDelete)
          }
        }
        return event
      }
    }
    HStack {
      Button(action: {
        newFolderToData(title: "Some Folder")
      }) {
        Image(systemName: "folder.badge.plus")
      }
      
      Button(action: {
        saveCurrentPromptToData(title: currentPrompt.positivePrompt)
      }) {
        Image(systemName: "plus.bubble")
      }
    }
    .frame(height: 30).padding(.bottom, 10)
  }
}

#Preview {
  SidebarListView(
    selectedImage: .constant(MockDataController.shared.lastImage),
    lastSavedImageUrls: .constant(MockDataController.shared.mockImageUrls)
  )
  .modelContainer(MockDataController.shared.container)
  .frame(width: 200)
}

/*
struct SidebarListView_Previews: PreviewProvider {
  // Mock data models
  static let mockPromptModel = PromptModel() // Configure with default or mock values
  static let mockSidebarItems = [SidebarItem]() // Populate with mock `SidebarItem` instances
  static let mockSidebarFolders = [SidebarFolder]() // Populate with mock `SidebarFolder` instances
  
  static var previews: some View {
    // Provide mock environment and objects
    SidebarListView(
      selectedImage: .constant(NSImage()), // Provide a default or mock NSImage
      lastSavedImageUrls: .constant([URL]()) // Provide a default or mock array of URLs
    )
    .environment(\.modelContext, MockModelContext()) // Mock your ModelContext
    .environmentObject(mockPromptModel) // Provide the mock environment object
  }
  
  // Mock ModelContext or any other required environments
  static func MockModelContext() -> some ModelContext {
    // Implement a mock version of your ModelContext
    // This might involve creating a mock database or a simple in-memory store
  }
}
*/
