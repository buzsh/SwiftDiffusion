//
//  CheckpointModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import Foundation

enum CheckpointModelType {
  case coreMl
  case python
}

class CheckpointModel: ObservableObject, Identifiable {
  let id = UUID()
  let name: String
  let path: String
  let type: CheckpointModelType
  var checkpointApiModel: CheckpointApiModel?
  
  init(name: String, path: String, type: CheckpointModelType, checkpointApiModel: CheckpointApiModel? = nil) {
    self.name = name
    self.path = path
    self.type = type
    self.checkpointApiModel = checkpointApiModel
  }
}

extension CheckpointModel: Equatable {
  static func == (lhs: CheckpointModel, rhs: CheckpointModel) -> Bool {
    return lhs.id == rhs.id
  }
}
