//
//  DetailView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI
import AppKit

struct DetailImageView: View {
  @Binding var image: NSImage?
  
  var body: some View {
    VStack {
      if let image = image {
        Image(nsImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
      } else {
        Spacer()
        HStack {
          Spacer()
          SFSymbol.photo.image
            .font(.system(size: 30, weight: .light))
            .foregroundColor(Color.secondary)
            .opacity(0.5)
          Spacer()
        }
        Spacer()
      }
    }
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

struct HorizontalDivider: View {
  var lightColor: Color = .gray.opacity(0.25)
  var darkColor: Color = .black
  var thickness: CGFloat = 1
  
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    Rectangle()
      .fill(currentColor)
      .frame(height: thickness)
      .edgesIgnoringSafeArea(.all)
  }
  
  private var currentColor: Color {
    colorScheme == .dark ? darkColor : lightColor
  }
}

struct VerticalDivider: View {
  var lightColor: Color = .gray.opacity(0.25)
  var darkColor: Color = .black
  var thickness: CGFloat = 1
  
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    Rectangle()
      .fill(currentColor)
      .frame(width: thickness)
      .edgesIgnoringSafeArea(.all)
  }
  
  private var currentColor: Color {
    colorScheme == .dark ? darkColor : lightColor
  }
}
