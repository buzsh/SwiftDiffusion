//
//  CommonPreviews.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct CommonPreviews {
  @MainActor static var contentView: some View {
    return ContentView(
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .preview()
    .navigationTitle("")
  }
}

extension CommonPreviews {
  @MainActor static var promptView: some View {
    return PromptView(
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
    .preview()
  }
}

extension CommonPreviews {
  static var detailView: some View {
    let mockFileHierarchy = FileHierarchy(rootPath: UserSettings.shared.outputDirectoryPath)
    let progressViewModel = ProgressViewModel()
    progressViewModel.progress = 20.0
    
    return DetailView(
      fileHierarchyObject: mockFileHierarchy,
      selectedImage: .constant(nil),
      lastSelectedImagePath: .constant(""),
      scriptManager: ScriptManager.preview(withState: .readyToStart)
    )
  }
}

extension CommonPreviews {
  @MainActor static var sidebar: some View {
    return Sidebar(
      selectedImage: .constant(nil),
      lastSavedImageUrls: .constant([])
    )
    .preview()
    .navigationTitle("")
  }
}

#Preview("ContentView") {
  CommonPreviews.contentView
    .frame(width: 900, height: 800)
}

#Preview("PromptView") {
  CommonPreviews.promptView
    .frame(width: 600, height: 800)
}

#Preview("DetailView") {
  CommonPreviews.detailView
    .frame(width: 300, height: 600)
}

#Preview("Sidebar") {
  CommonPreviews.sidebar
    .frame(width: 300, height: 600)
}

extension ScriptManager {
  static func preview(withState state: ScriptState) -> ScriptManager {
    let previewManager = ScriptManager()
    previewManager.scriptState = state
    previewManager.serviceUrl = URL(string: "http://127.0.0.1:7860")
    return previewManager
  }
}
