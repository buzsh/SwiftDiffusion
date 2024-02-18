//
//  CheckpointMenu.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import SwiftUI

struct CheckpointMenu: View {
  @Binding var consoleLog: String
  @ObservedObject var scriptManager: ScriptManager
  var checkpointsManager: CheckpointsManager
  var currentPrompt: PromptModel
  
  func selectMenuItem(forModel model: CheckpointModel, ofType type: CheckpointModelType = .python) {
    consoleLog += "         Checkpoint.name: \(model.name)\n"
    consoleLog += "CheckpointMetadata.title: \(model.checkpointApiModel?.title ?? "nil")\n"
    consoleLog += "\n\n"
    currentPrompt.selectedModel = model
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Menu {
          Section(header: Text("􀢇 CoreML")) {
            ForEach(checkpointsManager.models.filter { $0.type == .coreMl }) { model in
              Button(model.name) {
                selectMenuItem(forModel: model, ofType: .coreMl)
              }
            }
          }
          Section(header: Text("􁻴 Python")) {
            ForEach(checkpointsManager.models.filter { $0.type == .python }) { model in
              Button(model.name) {
                selectMenuItem(forModel: model)
              }
            }
          }
        } label: {
          Label(currentPrompt.selectedModel?.name ?? "Choose Model", systemImage: "arkit")
        }
        if scriptManager.modelLoadState == .isLoading {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.5)
        }
      }
      .onChange(of: currentPrompt.selectedModel) {
        consoleLog += "CheckpointMenu.onChange(of: currentPrompt.selectedModel)\n\n"
      }
    }
  }
  
}

/*
extension CheckpointMenu {
  func updateSelectedCheckpointModel(with checkpointModel: CheckpointModel) {
    
    var canChangeModel: Bool {
      (scriptManager.scriptState == .active) && (scriptManager.modelLoadState == .idle || scriptManager.modelLoadState == .done)
    }
    
    if let checkpointModel = currentPrompt.selectedModel, let serviceUrl = scriptManager.serviceUrl {
      
      if canChangeModel {
        scriptManager.modelLoadState = .isLoading
        
        postAutomaticCheckpoint(forModel: checkpointModel, apiUrl: serviceUrl) { result in
          switch result {
          case .success(let successMessage):
            Debug.log("updateSelectedCheckpointModel Success: \(successMessage)")
            scriptManager.modelLoadState = .done
            
          case .failure(let error):
            Debug.log("updateSelectedCheckpointModel Failure: \(error)")
            scriptManager.modelLoadState = .failed
            
          }
        }
      }
    }
  }
}
 */

/*
extension CheckpointMenu {
  @MainActor
  /// Update currently loaded model checkpoint
  func postAutomaticCheckpoint(forModel checkpointModel: CheckpointModel, apiUrl: URL, completion: @escaping (Result<String, UpdateModelError>) -> Void) {
    guard let endpoint = prepareEndpoint(with: apiUrl) else { return }
    
    guard let request = prepareRequest(for: checkpointModel, endpoint: endpoint) else {
      completion(.failure(.nilCheckpoint))
      return
    }
    
    performRequest(request, completion: completion)
  }
  
  private func prepareEndpoint(with apiUrl: URL) -> URL? {
    return apiUrl.appendingPathComponent("/sdapi/v1/options")
  }
  
  private func prepareRequest(for checkpointModel: CheckpointModel, endpoint: URL) -> URLRequest? {
    guard let checkpointApiModel = checkpointModel.checkpointApiModel else {
      return nil
    }
    
    Debug.log("[API] attempting to POST \(checkpointModel):\n > \(checkpointApiModel.title)")
    
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let requestBody = UpdateSdModelCheckpointRequest(sdModelCheckpoint: checkpointApiModel.title)
    do {
      request.httpBody = try JSONEncoder().encode(requestBody)
      return request
    } catch {
      return nil
    }
  }
  
  private func performRequest(_ request: URLRequest, completion: @escaping (Result<String, UpdateModelError>) -> Void) {
    Task {
      do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
          completion(.failure(.invalidServerResponse))
          return
        }
        
        handleResponse(httpResponse, with: data, completion: completion)
      } catch {
        completion(.failure(.requestFailure(error.localizedDescription)))
      }
    }
  }
  
  private func handleResponse(_ httpResponse: HTTPURLResponse, with data: Data, completion: @escaping (Result<String, UpdateModelError>) -> Void) {
    switch httpResponse.statusCode {
    case 200:
      scriptManager.modelLoadState = .done
      completion(.success("Update successful."))
    case 422:
      scriptManager.modelLoadState = .failed
      if let validationError = try? JSONDecoder().decode(ValidationErrorResponse.self, from: data) {
        let errorMsg = validationError.detail.map { "\($0.msg)" }.joined(separator: ", ")
        completion(.failure(.validationError("Validation error: \(errorMsg)")))
      }
    default:
      completion(.failure(.unexpectedStatusCode(httpResponse.statusCode)))
    }
  }
}
*/
