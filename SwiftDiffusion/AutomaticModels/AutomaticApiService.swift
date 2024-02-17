//
//  AutomaticApiService.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation

class AutomaticApiService {
  static let shared = AutomaticApiService()
  private let scriptManager = ScriptManager.shared
  
  private init() {}
  
  func request(endpoint: String, httpMethod: String = "GET") async throws -> Data {
    guard let apiUrl = await scriptManager.serviceUrl,
          let url = URL(string: apiUrl.appendingPathComponent(endpoint).absoluteString) else {
      throw NetworkError.invalidURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = httpMethod
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw NetworkError.badResponse(statusCode: (response as? HTTPURLResponse)?.statusCode)
    }
    return data
  }
  
  enum NetworkError: Error {
    case invalidURL
    case badResponse(statusCode: Int? = nil)
  }
}
