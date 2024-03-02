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
  @State private var isHovering: Bool = true//false
  
  @State private var showDeleteFolderConfirmationAlert: Bool = false
  
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
          .onAppear {
            isHovering = true
            Delay.by(2) {
              isHovering = false
            }
          }
      }
      
      Spacer()
      
      Group {
        if isEditing {
          Button(action: {
            isEditing = false
            sidebarModel.currentFolder?.name = editableName
            sidebarModel.saveData(in: modelContext)
          }) {
            Image(systemName: "checkmark")
          }
          .buttonStyle(.accessoryBar)
          
        } else {
          Button(action: {
            isEditing = true
            editableName = sidebarModel.currentFolder?.name ?? ""
          }) {
            Image(systemName: "pencil")
          }
          .buttonStyle(.accessoryBar)
        }
        
        Button(action: {
          if let folder = sidebarModel.currentFolder {
            Debug.log("folder = folder")
            for item in folder.folders {
              Debug.log(" > folder.folders.name: \(item.name)")
            }
            for item in folder.items {
              Debug.log(" > folder.items.name: \(item.title)")
            }
          }
          
          if let folder = folder, folder.folders.isEmpty && folder.items.isEmpty {
            deleteFolder()
          } else {
            showDeleteFolderConfirmationAlert = true
          }
        }) {
          Image(systemName: "trash")
        }
        .buttonStyle(.accessoryBar)
        .padding(.leading, 2)
      }
      .opacity(isHovering ? 1 : 0)
      .animation(.easeInOut, value: isHovering)
    }
    .listRowInsets(EdgeInsets())
    .onHover { hovering in
      if isEditing {
        isHovering = true
      } else if isHovering == true {
        Delay.by(1) { isHovering = false }
      } else {
        isHovering = hovering
      }
    }
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
    if let parentFolder = sidebarModel.currentFolder?.parent, let folder = folder {
      withAnimation {
        sidebarModel.setCurrentFolder(to: parentFolder)
        parentFolder.remove(folder: folder)
        sidebarModel.saveData(in: modelContext)
        sidebarModel.sidebarFolderHasJustBeenDeleted = true
      }
    }
  }
}
