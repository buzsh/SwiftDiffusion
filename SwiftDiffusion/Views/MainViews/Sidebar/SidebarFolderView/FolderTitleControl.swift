//
//  FolderTitleControl.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/29/24.
//

import SwiftUI

struct FolderTitleControl: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  let folder: SidebarFolder?
  @State private var isEditing: Bool = false
  @State private var editableName: String = ""
  
  func storeChanges() {
    isEditing = false
    sidebarModel.currentFolder?.name = editableName
    sidebarModel.saveData(in: modelContext)
  }
  
  var body: some View {
    Divider()
    
    HStack(spacing: 0) {
      if isEditing {
        TextField("Untitled", text: $editableName, onCommit: {
          storeChanges()
        })
        .textFieldStyle(RoundedBorderTextFieldStyle())
      } else {
        Text(sidebarModel.currentFolder?.name ?? "Untitled")
          .fontWeight(.medium)
          .onTapGesture {
            isEditing = true
            editableName = sidebarModel.currentFolder?.name ?? ""
          }
      }
      
      Spacer()
      
      Group {
        if isEditing {
          AccessorySymbolButton(symbol: .checkmark, action: {
            isEditing = false
            sidebarModel.currentFolder?.name = editableName
            sidebarModel.saveData(in: modelContext)
          })
        } else {
          AccessorySymbolButton(symbol: .pencil, action: {
            isEditing = true
            editableName = sidebarModel.currentFolder?.name ?? ""
          })
        }
        
        TrashFolderButton(folder: folder)
          .padding(.leading, 2)
      }
      .frame(minWidth: 0)
    }
    .listRowInsets(EdgeInsets())
  }
}

struct TrashFolderButton: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  @State private var showDeleteFolderConfirmationAlert: Bool = false
  
  let folder: SidebarFolder?
  var body: some View {
    AccessorySymbolButton(symbol: .trash, action: {
      if let folder = folder, folder.folders.isEmpty && folder.items.isEmpty {
        deleteFolder()
      } else {
        showDeleteFolderConfirmationAlert = true
      }
    })
    .alert(isPresented: $showDeleteFolderConfirmationAlert) {
      Alert(
        title: Text("Are you sure you want to delete this folder?"),
        message: Text("All of its folders and items will be lost."),
        primaryButton: .destructive(Text("Delete")) {
          deleteFolder()
        },
        secondaryButton: .cancel()
      )
    }
  }
  
  func deleteFolder() {
    if let folder = folder, let parentFolder = sidebarModel.currentFolder?.parent  {
      withAnimation {
        sidebarModel.deleteFolder(folder, from: parentFolder)
      }
    }
  }
}
