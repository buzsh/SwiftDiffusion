//
//  VaeModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/25/24.
//

import Foundation
import Combine

extension Constants.API.Endpoint {
  struct Vae {
    static let get = "/sdapi/v1/sd-vae"
    static let refresh = "/sdapi/v1/refresh-vae"
  }
}

struct VaeModel: Identifiable, Decodable {
  var id = UUID()
  let name: String
  let path: String
  
  enum CodingKeys: String, CodingKey {
    case name = "model_name"
    case path = "filename"
  }
}

extension VaeModel: EndpointRepresentable {
  static var fetchEndpoint: String? {
    Constants.API.Endpoint.Vae.get
  }
  
  static var refreshEndpoint: String? {
    Constants.API.Endpoint.Vae.refresh
  }
}

extension VaeModel: Equatable {
  static func == (lhs: VaeModel, rhs: VaeModel) -> Bool {
    return lhs.id == rhs.id
  }
}
