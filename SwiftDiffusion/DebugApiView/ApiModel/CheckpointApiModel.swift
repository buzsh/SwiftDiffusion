//
//  CheckpointApiModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import Foundation
import Combine

class Checkpoint: ObservableObject, Identifiable {
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

struct CheckpointApiModel: Decodable {
  let title: String
  let modelName: String
  let hash: String?
  let sha256: String?
  let filename: String
  let config: String?
  
  enum CodingKeys: String, CodingKey {
    case title
    case modelName = "model_name"
    case hash
    case sha256
    case filename
    case config
  }
}

struct ClientConfig: Encodable, Decodable {
  let sdModelCheckpoint: String
  enum CodingKeys: String, CodingKey {
    case sdModelCheckpoint = "sd_model_checkpoint"
  }
}
