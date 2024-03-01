//
//  StoredCheckpointModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import Foundation
import SwiftData

@Model
class StoredCheckpointModel {
  @Attribute var name: String
  @Attribute var path: String
  @Attribute var type: StoredCheckpointModelType
  @Attribute var storedCheckpointApiModel: StoredCheckpointApiModel?
  
  init(name: String, path: String, type: StoredCheckpointModelType, storedCheckpointApiModel: StoredCheckpointApiModel? = nil) {
    self.name = name
    self.path = path
    self.type = type
    self.storedCheckpointApiModel = storedCheckpointApiModel
  }
}

enum StoredCheckpointModelType: String, Codable {
  case coreMl = "coreMl"
  case python = "python"
}

extension MapModelData {
  
  @MainActor 
  func toStoredCheckpointModel(from checkpointModel: CheckpointModel?) -> StoredCheckpointModel? {
    guard let checkpointModel = checkpointModel else { return nil }
    let storedCheckpointModelType = toStoredCheckpointModelType(from: checkpointModel.type)
    let storedCheckpointApiModel = toStoredCheckpointApiModel(from: checkpointModel.checkpointApiModel)
    return StoredCheckpointModel(name: checkpointModel.name,
                                 path: checkpointModel.path,
                                 type: storedCheckpointModelType,
                                 storedCheckpointApiModel: storedCheckpointApiModel
    )
  }
  
  @MainActor 
  func toCheckpointModel(from storedCheckpointModel: StoredCheckpointModel?) -> CheckpointModel? {
    guard let storedCheckpointModel = storedCheckpointModel else { return nil }
    let checkpointModelType = toCheckpointModelType(from: storedCheckpointModel.type)
    let checkpointApiModel = toCheckpointApiModel(from: storedCheckpointModel.storedCheckpointApiModel)
    
    return CheckpointModel(name: storedCheckpointModel.name,
                           path: storedCheckpointModel.path,
                           type: checkpointModelType,
                           checkpointApiModel: checkpointApiModel
    )
  }
  
  func toStoredCheckpointModelType(from type: CheckpointModelType) -> StoredCheckpointModelType {
    switch type {
    case .coreMl: return .coreMl
    case .python: return .python
    }
  }
  
  func toCheckpointModelType(from type: StoredCheckpointModelType) -> CheckpointModelType {
    switch type {
    case .coreMl: return .coreMl
    case .python: return .python
    }
  }
  
}
