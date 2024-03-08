//
//  DetailView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI
import AppKit

struct DetailView: View {
  var fileHierarchyObject: FileHierarchy
  @Binding var selectedImage: NSImage?
  @Binding var lastSelectedImagePath: String
  @ObservedObject var scriptManager = ScriptManager.shared
  
  @StateObject private var imageWindowManager = ImageWindowManager()
  @State private var showingFullscreenImage = false
  
  var body: some View {
    VSplitView {
      DetailImageView(image: $selectedImage)
        .frame(minHeight: 200, idealHeight: 400)
      detailToolbarAndFileBrowserView
        .frame(minHeight: 140, idealHeight: 200)
    }
  }
  
  private var detailToolbarAndFileBrowserView: some View {
    VStack(spacing: 0) {
      detailToolbarView
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 30, maxHeight: 30)
        .background(.bar)
      
      HorizontalDivider()
      
      FileOutlineView(fileHierarchyObject: fileHierarchyObject, selectedImage: $selectedImage, onSelectImage: { imagePath in
        lastSelectedImagePath = imagePath
      }, lastSelectedImagePath: lastSelectedImagePath)
    }
  }
  
  private var detailToolbarView: some View {
    HStack(spacing: 0) {
      DetailToolbarSymbolButton(hint: "Previous Image", symbol: .back, action: {
        if let previousImageNode = fileHierarchyObject.previousImage(currentPath: lastSelectedImagePath),
           let image = NSImage(contentsOfFile: previousImageNode.fullPath) {
          selectedImage = image
          lastSelectedImagePath = previousImageNode.fullPath
        }
      })
      
      VerticalDivider()
      
      Spacer()
      
      if fileHierarchyObject.isLoading {
        ProgressView()
          .progressViewStyle(.circular)
          .controlSize(.small)
          .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
      } else {
        DetailToolbarSymbolButton(hint: "Refresh Folders", symbol: .refresh, action: {
          Task {
            await fileHierarchyObject.refresh()
          }
        })
      }
      
      Spacer()
      
      DetailToolbarSymbolButton(hint: "Most Recent Image", symbol: .mostRecent, action: {
        Task {
          if let mostRecentImageNode = await fileHierarchyObject.findMostRecentlyModifiedImageFile(),
             let image = NSImage(contentsOfFile: mostRecentImageNode.fullPath) {
            selectedImage = image
            lastSelectedImagePath = mostRecentImageNode.fullPath
          }
        }
      })
      
      Spacer()
      
      ShareButton(selectedImage: $selectedImage)
      
      Spacer()
      
      DetailToolbarSymbolButton(hint: "Reveal in Finder", symbol: .folder, action: {
        NSWorkspace.shared.selectFile(lastSelectedImagePath, inFileViewerRootedAtPath: "")
      })
      .disabled(lastSelectedImagePath.isEmpty)
      
      Spacer()
      
      DetailToolbarSymbolButton(hint: "Fullscreen Image", symbol: .fullscreen, action: {
        if let image = selectedImage {
          imageWindowManager.openImageWindow(with: image)
        }
      })
      .disabled(selectedImage == nil)
      
      Spacer()
      
      VerticalDivider()
      
      DetailToolbarSymbolButton(hint: "Next Image", symbol: .forward, action: {
        if let nextImageNode = fileHierarchyObject.nextImage(currentPath: lastSelectedImagePath),
           let image = NSImage(contentsOfFile: nextImageNode.fullPath) {
          selectedImage = image
          lastSelectedImagePath = nextImageNode.fullPath
        }
      })
    }
  }
}

#Preview {
  CommonPreviews.detailView
}

extension CommonPreviews {
  static var detailView: some View {
    print(UserSettings.shared.outputDirectoryPath)
    let mockFileHierarchy = FileHierarchy(rootPath: UserSettings.shared.outputDirectoryPath)
    let progressViewModel = ProgressViewModel()
    progressViewModel.progress = 20.0
    
    return DetailView(
      fileHierarchyObject: mockFileHierarchy,
      selectedImage: .constant(nil),
      lastSelectedImagePath: .constant(""),
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .frame(width: 300, height: 600)
  }
}
