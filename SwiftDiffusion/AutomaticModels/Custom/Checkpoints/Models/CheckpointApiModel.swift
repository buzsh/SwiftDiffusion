//
//  CheckpointApiModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/21/24.
//

import Foundation

struct CheckpointApiModel: Decodable {
  let title: String
  let modelName: String
  let modelHash: String?
  let sha256: String?
  let filename: String
  let config: String?
  
  enum CodingKeys: String, CodingKey {
    case title
    case modelName = "model_name"
    case modelHash = "hash"
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
