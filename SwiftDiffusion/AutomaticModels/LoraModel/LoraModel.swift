//
//  LoraModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation
import Combine

extension Constants.API.Endpoint {
  struct Loras {
    static let get = "/sdapi/v1/loras"
    static let postRefresh = "/sdapi/v1/refresh-loras"
  }
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
    Constants.API.Endpoint.Loras.get
  }
  
  static var refreshEndpoint: String? {
    Constants.API.Endpoint.Loras.postRefresh
  }
}
