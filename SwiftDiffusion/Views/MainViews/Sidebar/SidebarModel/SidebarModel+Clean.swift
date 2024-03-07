//
//  SidebarModel+Clean.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/7/24.
//

import Foundation

extension SidebarModel {
  func cleanUpEmptyWorkspaceItems() {
    let emptyPromptItems = workspaceFolder.items.filter { $0.prompt?.isEmptyPrompt ?? false }
    for item in emptyPromptItems {
      workspaceFolder.remove(item: item)
    }
  }
}

extension StoredPromptModel {
  var isEmptyPrompt: Bool {
    return isWorkspaceItem == true &&
    selectedModel == nil &&
    samplingMethod == nil &&
    positivePrompt.isEmpty &&
    negativePrompt.isEmpty &&
    width == 512 &&
    height == 512 &&
    cfgScale == 7 &&
    samplingSteps == 20 &&
    seed == "-1" &&
    batchCount == 1 &&
    batchSize == 1 &&
    clipSkip == 1 &&
    vaeModel == nil
  }
}
