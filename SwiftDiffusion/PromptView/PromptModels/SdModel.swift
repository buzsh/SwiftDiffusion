//
//  SdModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation

struct SdModel: Decodable {
  let title: String
  let modelName: String
  let hash: String?
  let sha256: String?
  let filename: String
  let config: String?
  
  enum CodingKeys: String, CodingKey {
    case title
    case modelName = "model_name" // Corrected key mapping
    case hash
    case sha256
    case filename
    case config
  }
}

struct UpdateSdModelCheckpointRequest: Codable {
  let sdModelCheckpoint: String
  
  enum CodingKeys: String, CodingKey {
    case sdModelCheckpoint = "sd_model_checkpoint"
  }
}

struct ValidationErrorDetail: Codable {
  let loc: [String]
  let msg: String
  let type: String
}

struct ValidationErrorResponse: Codable {
  let detail: [ValidationErrorDetail]
}

enum UpdateModelError: Error {
  case nilCheckpoint
  case encodingError(String)
  case invalidServerResponse
  case validationError(String)
  case unexpectedStatusCode(Int)
  case requestFailure(String)
}

struct OptionsResponse: Decodable {
  let samplesSave: Bool
  let samplesFormat: String
  // Add other properties as needed...
  let sdModelCheckpoint: String
  // Use CodingKeys to match JSON keys with Swift property names
  enum CodingKeys: String, CodingKey {
    case samplesSave = "samples_save"
    case samplesFormat = "samples_format"
    // Map other properties...
    case sdModelCheckpoint = "sd_model_checkpoint"
  }
}

extension PromptView {
  @MainActor
  /// Update automatic1111 currently loaded model checkpoint
  func updateSdModelCheckpoint(forModel modelItem: ModelItem, apiUrl: URL, completion: @escaping (Result<String, UpdateModelError>) -> Void) {
    let endpoint = apiUrl.appendingPathComponent("/sdapi/v1/options")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    guard let sdModelCheckpoint = modelItem.sdModel else {
      completion(.failure(.nilCheckpoint))
      return
    }
    
    Debug.log("[API] attempting to POST \(modelItem):\n > \(sdModelCheckpoint.title)")
    
    let requestBody = UpdateSdModelCheckpointRequest(sdModelCheckpoint: sdModelCheckpoint.title)
    do {
      request.httpBody = try JSONEncoder().encode(requestBody)
    } catch {
      completion(.failure(.encodingError(error.localizedDescription)))
      return
    }
    
    Task {
      do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
          completion(.failure(.invalidServerResponse))
          return
        }
        
        switch httpResponse.statusCode {
        case 200:
          scriptManager.modelLoadState = .done
          completion(.success("Update successful for model: \(sdModelCheckpoint)."))
        case 422:
          scriptManager.modelLoadState = .failed
          let decoder = JSONDecoder()
          let validationError = try decoder.decode(ValidationErrorResponse.self, from: data)
          let errorMsg = validationError.detail.map { "\($0.msg)" }.joined(separator: ", ")
          completion(.failure(.validationError("Validation error: \(errorMsg)")))
        default:
          completion(.failure(.unexpectedStatusCode(httpResponse.statusCode)))
        }
      } catch {
        completion(.failure(.requestFailure(error.localizedDescription)))
      }
    }
  }
  
}
