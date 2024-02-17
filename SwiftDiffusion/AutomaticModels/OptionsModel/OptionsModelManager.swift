//
//  OptionsModelManager.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation
import Combine

class OptionsModelManager: ObservableObject {
  @Published var optionsModel: OptionsModel?
  @Published var isLoading: Bool = false
  @Published var error: Error?
  
  private var cancellables = Set<AnyCancellable>()
  private let scriptManager = ScriptManager.shared
  
  func fetchOptionsModel() {
    isLoading = true
    Task {
      do {
        guard let apiUrl = await scriptManager.serviceUrl else {
          Debug.log("Service URL is nil.")
          self.isLoading = false
          return
        }
        
        let endpoint = apiUrl.appendingPathComponent(Constants.API.Endpoint.Options.get)
        let (data, _) = try await URLSession.shared.data(from: endpoint)
        let decoder = JSONDecoder()
        let optionsResponse = try decoder.decode(OptionsModel.self, from: data)
        
        DispatchQueue.main.async {
          self.optionsModel = optionsResponse
          self.isLoading = false
          Debug.log("Fetched OptionsModel successfully: \(optionsResponse)")
        }
      } catch {
        DispatchQueue.main.async {
          self.error = error
          self.isLoading = false
          Debug.log("Failed to fetch or parse options data: \(error.localizedDescription)")
        }
      }
    }
  }
  
  func getLoadedPythonCheckpointModel(_ pythonCheckpointModels: [PythonCheckpointModel]) -> PythonCheckpointModel? {
    guard let sdModelCheckpoint = self.optionsModel?.sdModelCheckpoint else {
      Debug.log("SD Model Checkpoint is nil.")
      return nil
    }
    
    return pythonCheckpointModels.first { $0.title == sdModelCheckpoint }
  }
  
  @MainActor
  func postLoadPythonCheckpointModel(forModel modelItem: PythonCheckpointModel, apiUrl: URL, completion: @escaping (Result<String, UpdateModelError>) -> Void) {
    let endpoint = apiUrl.appendingPathComponent("/sdapi/v1/options")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    guard let sdModelCheckpoint = optionsModel?.sdModelCheckpoint else {
      completion(.failure(.nilCheckpoint))
      return
    }
    
    Debug.log("[API] attempting to POST \(modelItem):\n > \(sdModelCheckpoint)")
    
    let requestBody = UpdateSdModelCheckpointRequest(sdModelCheckpoint: sdModelCheckpoint)
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
