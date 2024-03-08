//
//  DetailView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI
import AppKit

extension Constants.Layout {
  struct Toolbar {
    static let itemHeight: CGFloat = 30
    static let itemWidth: CGFloat = 30
  }
}

struct DetailToolbarSymbolButton: View {
  let symbol: SFSymbol
  let action: () -> Void
  
  private let itemHeight: CGFloat = 30
  private let itemWidth: CGFloat = 30
  
  var body: some View {
    Button(action: action) {
      symbol.image
    }
    .buttonStyle(BorderlessButtonStyle())
    .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
  }
}

struct DetailView: View {
  var fileHierarchyObject: FileHierarchy
  @Binding var selectedImage: NSImage?
  @Binding var lastSelectedImagePath: String
  @ObservedObject var scriptManager = ScriptManager.shared
  
  @StateObject private var imageWindowManager = ImageWindowManager()
  @State private var showingFullscreenImage = false
  
  var body: some View {
    VSplitView {
      VStack {
        if let selectedImage = selectedImage {
          Image(nsImage: selectedImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
        } else {
          Spacer()
          HStack {
            Spacer()
            Image(systemName: "photo") // app.dashed
              .font(.system(size: 30, weight: .light))
              .foregroundColor(Color.secondary)
              .opacity(0.5)
            Spacer()
          }
          Spacer()
        }
        
      }
      .frame(minHeight: 200, idealHeight: 400)
      
      HStack(spacing: 0) {
        Button(action: {
          if let previousImageNode = fileHierarchyObject.previousImage(currentPath: lastSelectedImagePath) {
            if let image = NSImage(contentsOfFile: previousImageNode.fullPath) {
              self.selectedImage = image
              self.lastSelectedImagePath = previousImageNode.fullPath
            }
          }
        }) {
          Image(systemName: "arrow.left")
        }
        .buttonStyle(BorderlessButtonStyle())
        .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
        
        Divider()
        
        Spacer()
        
        if fileHierarchyObject.isLoading {
          ProgressView()
            .progressViewStyle(.circular)
            .controlSize(.small)
            .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
        } else {
          Button(action: {
            Task {
              await self.fileHierarchyObject.refresh()
            }
          }) {
            Image(systemName: "arrow.clockwise")
          }
          .buttonStyle(BorderlessButtonStyle())
          .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
        }
        
        Spacer()
        
        // Most recent image button
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
          Image(systemName: "clock.arrow.circlepath")
        }
        .buttonStyle(BorderlessButtonStyle())
        .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
        
        Spacer()
        
        ShareButton(selectedImage: $selectedImage)
        
        Spacer()
        
        // Reveal in finder
        Button(action: {
          Debug.log("lastSelectedImagePath: \(lastSelectedImagePath)")
          if !lastSelectedImagePath.isEmpty {
            NSWorkspace.shared.selectFile(lastSelectedImagePath, inFileViewerRootedAtPath: "")
          }
        }) {
          Image(systemName: "folder")
        }
        .buttonStyle(BorderlessButtonStyle())
        .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
        
        Spacer()
        
        // Fullscreen image button
        Button(action: {
          if let image = selectedImage {
            imageWindowManager.openImageWindow(with: image)
          }
        }) {
          Image(systemName: "arrow.up.left.and.arrow.down.right")
        }
        .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
        .buttonStyle(BorderlessButtonStyle())
        .disabled(selectedImage == nil)
        
        Spacer()
        
        Divider()
        
        Button(action: {
          if let nextImageNode = fileHierarchyObject.nextImage(currentPath: lastSelectedImagePath) {
            if let image = NSImage(contentsOfFile: nextImageNode.fullPath) {
              self.selectedImage = image
              self.lastSelectedImagePath = nextImageNode.fullPath
            }
          }
        }) {
          Image(systemName: "arrow.right")
        }
        .buttonStyle(BorderlessButtonStyle())
        .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
      }
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

#Preview {
  let mockFileHierarchy = FileHierarchy(rootPath: "/Users/jb/Dev/GitHub/stable-diffusion-webui/outputs")
  @State var selectedImage: NSImage? = nil
  @State var lastSelectedImagePath: String = ""
  let progressViewModel = ProgressViewModel()
  progressViewModel.progress = 20.0
  
  return DetailView(fileHierarchyObject: mockFileHierarchy, selectedImage: $selectedImage, lastSelectedImagePath: $lastSelectedImagePath, scriptManager: ScriptManager.preview(withState: .readyToStart)).frame(width: 300, height: 600)
}
