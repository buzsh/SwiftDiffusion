//
//  SdModelData.swift
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

extension PromptView {
  func getSdModelData(_ api: URL) async throws -> [SdModel] {
    let endpoint = api.appendingPathComponent("/sdapi/v1/sd-models")
    let (data, _) = try await URLSession.shared.data(from: endpoint)
    let decoder = JSONDecoder()
    let models = try decoder.decode([SdModel].self, from: data)
    return models
  }
  
  @MainActor
  func assignSdModelCheckpointTitles(completion: @escaping () -> Void) {
    guard let baseUrl = scriptManager.serviceUrl else {
      completion()
      return
    }
    
    Task {
      do {
        let models = try await getSdModelData(baseUrl)
        var unassignedItems: [ModelItem] = []
        
        // Log all filenames from the API for comparison
        let apiFilenames = models.map { URL(fileURLWithPath: $0.filename).lastPathComponent }
        Debug.log("API Filenames: \(apiFilenames)")
        
        for item in modelManager.items where item.sdModelCheckpoint == nil {
          let itemFilename = item.url.lastPathComponent
          if let matchingModel = models.first(where: { URL(fileURLWithPath: $0.filename).lastPathComponent == itemFilename }) {
            item.sdModelCheckpoint = matchingModel.title
            Debug.log("Assigned \(matchingModel.title) to \(item.name)")
          } else {
            unassignedItems.append(item)
            Debug.log("No match for \(item.name) with filename \(itemFilename)")
          }
        }
        
        // Log unassigned ModelItems
        for item in unassignedItems {
          Debug.log("ModelItem still without sdModelCheckpoint: \(item.name)")
        }
        
        completion()
      } catch {
        Debug.log("Failed to fetch SD Model Data: \(error)")
        completion()
      }
    }
  }
 
  
  @MainActor
  func updateSdModelCheckpoint(forModel modelItem: ModelItem, apiUrl: URL, completion: @escaping (String) -> Void) {
    let endpoint = apiUrl.appendingPathComponent("/sdapi/v1/options")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    guard let sdModelCheckpoint = modelItem.sdModelCheckpoint else {
      completion("ModelItem sdModelCheckpoint is nil.")
      return
    }
    
    let requestBody = UpdateSdModelCheckpointRequest(sdModelCheckpoint: sdModelCheckpoint)
    do {
      request.httpBody = try JSONEncoder().encode(requestBody)
    } catch {
      completion("Failed to encode request body: \(error.localizedDescription)")
      return
    }
    
    Task {
      do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
          completion("Invalid response from server.")
          return
        }
        
        switch httpResponse.statusCode {
        case 200:
          completion("Update successful for model: \(sdModelCheckpoint).")
        case 422:
          let decoder = JSONDecoder()
          let validationError = try decoder.decode(ValidationErrorResponse.self, from: data)
          let errorMsg = validationError.detail.map { "\($0.msg)" }.joined(separator: ", ")
          completion("Validation error: \(errorMsg)")
        default:
          completion("Unexpected server response: \(httpResponse.statusCode)")
        }
      } catch {
        completion("Failed to perform request: \(error.localizedDescription)")
      }
    }
  }
  
  
}
