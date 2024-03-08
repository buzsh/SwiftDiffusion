//
//  PastableDataManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/7/24.
//

import Foundation

class PastableDataManager: ObservableObject {
  private var checkpointsManager: CheckpointsManager!
  private var vaeModelsManager: ModelManager<VaeModel>!
  
  @Published var canPasteData: Bool = false
  @Published var pastablePromptData: StoredPromptModel? = nil
  
  static var shared: PastableDataManager = {
    fatalError("PastableDataManager.shared has not been initialized. Call PastableDataManager.setup(...) first.")
  }()
  
  static func setup(withCheckpointsManager checkpointsManager: CheckpointsManager, vaeModelsManager: ModelManager<VaeModel>) {
    let manager = PastableDataManager()
    manager.checkpointsManager = checkpointsManager
    manager.vaeModelsManager = vaeModelsManager
    shared = manager
  }
  
  private init() {}
  
  func parsePasteboard(_ pasteboardContent: String) {
    canPasteData = didFindGenerationDataTags(from: pasteboardContent)
    
    if canPasteData {
      //let parseCivitai = ParseCivitai(checkpointsManager: checkpointsManager, vaeModelsManager: vaeModelsManager)
      //parseCivitai.
    }
  }
  
  /// Determines if the pasteboard content contains generation data by looking for specific keywords.
  func didFindGenerationDataTags(from pasteboardContent: String) -> Bool {
    var relevantKeywordCounter = 0
    let keywords = ["Negative prompt:", "Steps:", "Seed:", "Sampler:", "CFG scale:", "Clip skip:", "Model:", "Model hash:"]
    
    for keyword in keywords {
      if pasteboardContent.contains(keyword) {
        relevantKeywordCounter += 1
      }
      
      if relevantKeywordCounter >= 2 {
        return true
      }
    }
    return false
  }
  
}
