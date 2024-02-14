//
//  SidebarListView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import SwiftUI
import SwiftData

struct SidebarListView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var currentPrompt: PromptModel
  
  @Query private var sidebarItems: [SidebarItem]
  @Query private var sidebarFolders: [SidebarFolder]
  @State private var selectedItemID: UUID?
  @State private var editingItemId: UUID? = nil
  @State private var draftTitle: String = ""
  
  @Binding var selectedImage: NSImage?
  @Binding var lastSavedImageUrls: [URL]
  
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
    //print("savePromptToData promptData.SdModel \(String(describing: promptData?.selectedModel?.name))")
    
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
    let itemToDelete = sidebarItems[index]
    modelContext.delete(itemToDelete)
    do {
      try modelContext.save()
    } catch {
      Debug.log("Failed to delete item: \(error.localizedDescription)")
    }
    let nextSelectionIndex = determineNextSelectionIndex(afterDeleting: index)
    updateSelection(to: nextSelectionIndex)
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
  
  var body: some View {
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
  }
}

/*
 #Preview {
 SidebarListView()
 }
 */
