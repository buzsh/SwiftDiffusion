//
//  MapModelData.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import Foundation

struct MapModelData {
  @MainActor
  func toStored(promptModel: PromptModel) -> StoredPromptModel? {
    return toStoredPromptModel(from: promptModel)
  }
  
  @MainActor
  func fromStored(storedPromptModel: StoredPromptModel) -> PromptModel {
    return toPromptModel(from: storedPromptModel)
  }
  
}
