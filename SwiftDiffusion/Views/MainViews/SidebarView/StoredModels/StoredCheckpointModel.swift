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
  func mapCheckpointModelToStoredCheckpointModel(_ checkpointModel: CheckpointModel?) -> StoredCheckpointModel? {
    guard let checkpointModel = checkpointModel else { return nil }
    let storedCheckpointModelType = mapCheckpointModelTypeToStoredCheckpointModelType(checkpointModel.type)
    let storedCheckpointApiModel = mapCheckpointApiModelToStoredCheckpointApiModel(checkpointModel.checkpointApiModel)
    return StoredCheckpointModel(name: checkpointModel.name,
                                 path: checkpointModel.path,
                                 type: storedCheckpointModelType,
                                 storedCheckpointApiModel: storedCheckpointApiModel
                                 )
  }
  
  @MainActor 
  func mapStoredCheckpointModelToCheckpointModel(_ storedCheckpointModel: StoredCheckpointModel?) -> CheckpointModel? {
    guard let storedCheckpointModel = storedCheckpointModel else { return nil }
    let checkpointModelType = mapStoredCheckpointModelTypeToCheckpointModelType(storedCheckpointModel.type)
    let checkpointApiModel = mapStoredCheckpointApiModelToCheckpointApiModel(storedCheckpointApiModel: storedCheckpointModel.storedCheckpointApiModel)
    
    return CheckpointModel(name: storedCheckpointModel.name,
                           path: storedCheckpointModel.path,
                           type: checkpointModelType,
                           checkpointApiModel: checkpointApiModel
                           )
  }
  
  func mapCheckpointModelTypeToStoredCheckpointModelType(_ type: CheckpointModelType) -> StoredCheckpointModelType {
    switch type {
    case .coreMl: return .coreMl
    case .python: return .python
    }
  }
  
  func mapStoredCheckpointModelTypeToCheckpointModelType(_ type: StoredCheckpointModelType) -> CheckpointModelType {
    switch type {
    case .coreMl: return .coreMl
    case .python: return .python
    }
  }
  
}
