//
//  LoraModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation
import Combine

extension Constants.API.Endpoint {
  static let getLoras = "/sdapi/v1/loras"
  static let postRefreshLoras = "/sdapi/v1/refresh-loras"
}

struct LoraModel: Identifiable, Decodable {
  var id = UUID()
  let name: String
  let alias: String
  let path: String
  
  enum CodingKeys: String, CodingKey {
    case name, alias, path
  }
}

extension LoraModel: EndpointRepresentable {
  static var fetchEndpoint: String {
    Constants.API.Endpoint.getLoras
  }
  
  static var refreshEndpoint: String? {
    Constants.API.Endpoint.postRefreshLoras
  }
}
