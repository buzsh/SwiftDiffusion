//
//  PythonCheckpointModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

extension Constants.API.Endpoint {
  struct Checkpoints {
    static let get = "/sdapi/v1/sd-models"
    static let postRefresh = "/sdapi/v1/refresh-checkpoints"
  }
}

struct PythonCheckpointModel: Identifiable, Decodable {
  var id = UUID()
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

extension PythonCheckpointModel: EndpointRepresentable {
  static var fetchEndpoint: String {
    Constants.API.Endpoint.Checkpoints.get
  }
  
  static var refreshEndpoint: String? {
    Constants.API.Endpoint.Checkpoints.postRefresh
  }
}

extension PythonCheckpointModel: Equatable {
  static func == (lhs: PythonCheckpointModel, rhs: PythonCheckpointModel) -> Bool {
    return lhs.id == rhs.id
  }
}
