//
//  DetailView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct DetailView: View {
  var fileHierarchyObject: FileHierarchy
  @Binding var selectedImage: NSImage?
  @Binding var lastSelectedImagePath: String
  @ObservedObject var scriptManager: ScriptManager
  
  var body: some View {
    VSplitView {
      VStack {
        if let selectedImage = selectedImage {
          Image(nsImage: selectedImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
        } else if NSImage(named: "DiffusionPlaceholder") != nil {
          Image(nsImage: NSImage(named: "DiffusionPlaceholder")!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
        } else {
          Rectangle()
            .foregroundColor(.gray)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
        }
      }
      .frame(minHeight: 200, idealHeight: 400)
      
      HStack {
        Button(action: {
          Task {
            await self.fileHierarchyObject.refresh()
          }
        }) {
          Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(BorderlessButtonStyle())
        
        if fileHierarchyObject.isLoading {
          ProgressView()
            .progressViewStyle(.circular)
            .controlSize(.small)
            .padding(.leading, 5)
        }
        
        Spacer()
        
        if scriptManager.genStatus != .idle {
          ProgressView(value: scriptManager.genProgress)
            .progressViewStyle(LinearProgressViewStyle())
            .frame(width: 100)
            .onChange(of: scriptManager.genStatus) {
              if scriptManager.genStatus == .done {
                Task {
                  await self.fileHierarchyObject.refresh()
                }
              }
            }
        }
        
        /*
        if scriptManager.genStatus != .idle {
          
              if scriptManager.genStatus == .done {
                Task {
                  await self.fileHierarchyObject.refresh()
                }
            }
        }*/
        

        //Text("\(Int(scriptManager.genProgress * 100))%").padding(.leading, 5)
        
        Spacer()
        
        Button(action: {
          Task {
            if let mostRecentImageNode = await fileHierarchyObject.findMostRecentlyModifiedImageFile() {
              if let image = NSImage(contentsOfFile: mostRecentImageNode.fullPath) {
                self.selectedImage = image
                self.lastSelectedImagePath = mostRecentImageNode.fullPath
              }
            }
          }
        }) {
          Image(systemName: "link")
        }
        .buttonStyle(BorderlessButtonStyle())
        
        Button(action: {
          Debug.log("lastSelectedImagePath: \(lastSelectedImagePath)")
        }) {
          Image(systemName: "questionmark")
        }
        .buttonStyle(BorderlessButtonStyle())
      }
      .padding(.horizontal, 18)
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 30, maxHeight: 30)
      .background(.bar)
      
      FileOutlineView(fileHierarchyObject: fileHierarchyObject, selectedImage: $selectedImage, onSelectImage: { imagePath in
        lastSelectedImagePath = imagePath
      }, lastSelectedImagePath: lastSelectedImagePath)
      .frame(minWidth: 250, idealWidth: 300, maxWidth: .infinity)
      .frame(minHeight: 140, idealHeight: 200)
    }

  }
}

/*
#Preview {
  let mockFileHierarchy = FileHierarchy(rootPath: "/Users/jb/Dev/GitHub/stable-diffusion-webui/outputs")
  @State var selectedImage: NSImage? = nil
  @State var lastSelectedImagePath: String = ""
  let progressViewModel = ProgressViewModel()
  progressViewModel.progress = 20.0
  
  return DetailView(fileHierarchyObject: mockFileHierarchy, selectedImage: $selectedImage, lastSelectedImagePath: $lastSelectedImagePath, progressViewModel: progressViewModel).frame(width: 300, height: 600)
}
*/

extension FileHierarchy {
  func findMostRecentlyModifiedImageFile() async -> FileNode? {
    func isImageFile(_ path: String) -> Bool {
      let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff"]
      return imageExtensions.contains((path as NSString).pathExtension.lowercased())
    }
    
    func searchDirectory(_ directory: String) async -> FileNode? {
      var mostRecentImageNode: FileNode? = nil
      let fileManager = FileManager.default
      do {
        let items = try fileManager.contentsOfDirectory(atPath: directory)
        for item in items {
          let itemPath = (directory as NSString).appendingPathComponent(item)
          var isDir: ObjCBool = false
          fileManager.fileExists(atPath: itemPath, isDirectory: &isDir)
          if isDir.boolValue {
            // Recursively search in directories
            if let foundNode = await searchDirectory(itemPath) {
              if mostRecentImageNode == nil || foundNode.lastModified > mostRecentImageNode!.lastModified {
                mostRecentImageNode = foundNode
              }
            }
          } else if isImageFile(itemPath) {
            let attributes = try fileManager.attributesOfItem(atPath: itemPath)
            if let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date {
              let fileNode = FileNode(name: item, fullPath: itemPath, lastModified: modificationDate)
              if mostRecentImageNode == nil || fileNode.lastModified > mostRecentImageNode!.lastModified {
                mostRecentImageNode = fileNode
              }
            }
          }
        }
      } catch {
        Debug.log("Failed to list directory: \(error.localizedDescription)")
      }
      return mostRecentImageNode
    }
    
    return await searchDirectory(self.rootPath)
  }
}
