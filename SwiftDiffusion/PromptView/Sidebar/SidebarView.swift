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
  
  @State private var selectedItemID: UUID?
  @State private var selectedItemName: String?
  @State private var editingItemId: UUID? = nil
  @State private var draftTitle: String = ""
  
  @State private var showDeletionAlert: Bool = false
  @State private var itemToDelete: SidebarItem?
  
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
  
  func updatePromptAndSelectedImage(newPrompt: PromptModel, imageUrls: [URL]) {
    currentPrompt.updateProperties(from: newPrompt)
    
    if let lastImageUrl = imageUrls.last, let image = NSImage(contentsOf: lastImageUrl) {
      selectedImage = image
    }
  }
  
  var body: some View {
    Divider()
    
    HStack(spacing: 0) {
      Spacer()
      
      // Show model name
      Button(action: {
      }) {
        Image(systemName: "arkit")
      }
      .buttonStyle(BorderlessButtonStyle())
      .frame(width: Constants.Layout.SidebarToolbar.itemWidth, height: Constants.Layout.SidebarToolbar.itemHeight)
      Spacer()
      
      // Show thumbnails
      Button(action: {
      }) {
        Image(systemName: "photo")
      }
      .buttonStyle(BorderlessButtonStyle())
      .frame(width: Constants.Layout.SidebarToolbar.itemWidth, height: Constants.Layout.SidebarToolbar.itemHeight)
      
      Spacer()
    }
    .frame(height: Constants.Layout.SidebarToolbar.itemHeight)
    
    Divider()
    
    List(selection: $selectedItemID) {
      /*
       Section(header: Text("Unsaved")) {
       Text("New Prompt")
       }
       */
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
              
              // Conditional based on image select
              if let lastImageUrl = item.imageUrls.last {
                AsyncImage(url: lastImageUrl) { image in
                  image
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black, radius: 1, x: 0, y: 1)
                } placeholder: {
                  ProgressView()
                }
              }
              
              VStack(alignment: .leading) {
                Text(item.title)
                // Show this if arkit selected
                if let prompt = item.prompt {
                  if let modelName = prompt.selectedModel?.name {
                    Text(modelName)
                      .font(.system(size: 10, weight: .light, design: .rounded))
                  }
                }
                
              }
            }
            //.frame(height: 30)
            
            .tag(item.id)
            .opacity(editingItemId == nil ? 1 : 0.5) // De-emphasize non-editing items
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
            }.simultaneously(with: TapGesture(count: 2).onEnded {
              // This block ensures that double-tap has priority over single-tap
              // Prevent double-tap from affecting selection if already editing
              if editingItemId == nil {
                selectedItemID = nil // Clear selection here to enter edit mode
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
        saveCurrentPromptToData()
      }) {
        Image(systemName: "plus.bubble")
      }
    }
    .frame(height: 30).padding(.bottom, 10)
  }
}

#Preview {
  SidebarView(
    selectedImage: .constant(MockDataController.shared.lastImage),
    lastSavedImageUrls: .constant(MockDataController.shared.mockImageUrls)
  )
  .modelContainer(MockDataController.shared.container)
  .frame(width: 200)
}
