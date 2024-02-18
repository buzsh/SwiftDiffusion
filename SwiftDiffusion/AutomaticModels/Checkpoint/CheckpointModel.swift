//
//  CheckpointModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import Foundation
import Combine

enum CheckpointModelType {
  case coreMl
  case python
}

@MainActor
class CheckpointModel: ObservableObject, Identifiable {
  let id = UUID()
  let name: String
  let type: CheckpointModelType
  let url: URL
  var isDefaultModel: Bool = false
  var checkpointMetadata: CheckpointMetadata?

  @Published var preferences: CheckpointModelPreferences
  
  init(name: String, type: CheckpointModelType, url: URL, isDefaultModel: Bool = false, checkpointMetadata: CheckpointMetadata? = nil) {
    self.name = name
    self.type = type
    self.url = url
    self.isDefaultModel = isDefaultModel
    self.checkpointMetadata = checkpointMetadata
    self.preferences = CheckpointModelPreferences.defaultSamplingForCheckpointModelType(type: type)
  }
  
  func setCheckpointMetadata(_ automaticCheckpointModel: CheckpointMetadata) {
    self.checkpointMetadata = automaticCheckpointModel
  }
}

extension CheckpointModel: Equatable {
  static func == (lhs: CheckpointModel, rhs: CheckpointModel) -> Bool {
    return lhs.id == rhs.id
  }
}
