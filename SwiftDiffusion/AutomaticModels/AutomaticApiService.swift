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
    guard let apiUrl = await scriptManager.serviceUrl else {
      throw NetworkError.invalidURL
    }
    
    let fullUrl = apiUrl.appendingPathComponent(endpoint)
    
    var request = URLRequest(url: fullUrl)
    request.httpMethod = httpMethod
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      let statusCode = (response as? HTTPURLResponse)?.statusCode
      throw NetworkError.badResponse(statusCode: statusCode)
    }
    
    return data
  }
  
  enum NetworkError: Error {
    case invalidURL
    case badResponse(statusCode: Int? = nil)
  }
}
