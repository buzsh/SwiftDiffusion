//
//  LoraService.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

extension Constants.API.Endpoint {
  static let getLoras = "/sdapi/v1/loras"
  static let postRefreshLoras = "/sdapi/v1/refresh-loras"
}

class LoraService {
  static func fetchLoras() async throws -> [LoraModel] {
    let data = try await AutomaticApiService.shared.request(endpoint: Constants.API.Endpoint.getLoras)
    return try JSONDecoder().decode([LoraModel].self, from: data)
  }
  
  static func refreshLoras() async throws {
    try _ = await AutomaticApiService.shared.request(endpoint: Constants.API.Endpoint.postRefreshLoras, httpMethod: .post)
  }
}
