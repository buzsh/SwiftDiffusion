//
//  StoredCheckpointApiModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import Foundation
import SwiftData

@Model
class StoredCheckpointApiModel {
  @Attribute var title: String
  @Attribute var modelName: String
  @Attribute var modelHash: String?
  @Attribute var sha256: String?
  @Attribute var filename: String
  @Attribute var config: String?
  
  init(title: String, modelName: String, modelHash: String? = nil, sha256: String? = nil, filename: String, config: String? = nil) {
    self.title = title
    self.modelName = modelName
    self.modelHash = modelHash
    self.sha256 = sha256
    self.filename = filename
    self.config = config
  }
}

extension MapModelData {
  
  func mapStoredCheckpointApiModelToCheckpointApiModel(storedCheckpointApiModel: StoredCheckpointApiModel? = nil) -> CheckpointApiModel? {
    guard let storedApiModel = storedCheckpointApiModel else { return nil }
    return CheckpointApiModel(title: storedApiModel.title,
                              modelName: storedApiModel.modelName,
                              modelHash: storedApiModel.modelHash,
                              sha256: storedApiModel.sha256,
                              filename: storedApiModel.filename,
                              config: storedApiModel.config
                              )
  }
  
  func mapCheckpointApiModelToStoredCheckpointApiModel(_ checkpointApiModel: CheckpointApiModel?) -> StoredCheckpointApiModel? {
    guard let checkpointApiModel = checkpointApiModel else { return nil }
    
    return StoredCheckpointApiModel(title: checkpointApiModel.title,
                                    modelName: checkpointApiModel.modelName,
                                    modelHash: checkpointApiModel.modelHash,
                                    sha256: checkpointApiModel.sha256,
                                    filename: checkpointApiModel.filename,
                                    config: checkpointApiModel.config
                                    )
  }
  
}
