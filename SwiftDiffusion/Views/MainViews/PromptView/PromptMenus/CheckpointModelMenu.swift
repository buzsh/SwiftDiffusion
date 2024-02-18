//
//  CheckpointModelMenu.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import SwiftUI

/*
struct CheckpointModelMenu: View {
  @ObservedObject var scriptManager: ScriptManager
  //@EnvironmentObject var currentPrompt: PromptModel
  //@EnvironmentObject var checkpointModelsManager: CheckpointModelsManager
  
  var currentPrompt: PromptModel
  //var checkpointModelsManager: CheckpointModelsManager
  
  @State private var previousSelectedModel: CheckpointModel? = nil
  @State var promptViewHasLoadedInitialModel = false
  /// Sends an API request to load in the currently selected model from the PromptView model menu.
  /// - Note: Updates `scriptState` and `modelLoadState`.
  func updateSelectedCheckpointModel(with checkpointModel: CheckpointModel) {
    if previousSelectedModel?.checkpointMetadata?.title == checkpointModel.checkpointMetadata?.title {
      Debug.log("Model already loaded. Do not reload.")
      return
    }
    
    if scriptManager.scriptState.isActive { scriptManager.modelLoadState = .isLoading }
    
    if let checkpointModel = currentPrompt.selectedModel, let serviceUrl = scriptManager.serviceUrl {
      Debug.log("Attempting to updateSdModelCheckpoint with checkpointModel: \(String(describing: checkpointModel.name))")
      updateAutomaticCheckpoint(forModel: checkpointModel, apiUrl: serviceUrl) { result in
        switch result {
        case .success(let successMessage):
          Debug.log("[updateSdModelCheckpoint] Success: \(successMessage)")
          scriptManager.modelLoadState = .done
        case .failure(let error):
          Debug.log("[updateSdModelCheckpoint] Failure: \(error)")
          if promptViewHasLoadedInitialModel {
            scriptManager.modelLoadState = .failed
          }
        }
      }
    }
    
    if scriptManager.scriptState.isActive { previousSelectedModel = checkpointModel }
  }
  
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
  
  
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        PromptRowHeading(title: "Model")
      }
      HStack {
        Menu {
          Section(header: Text("􀢇 CoreML")) {
            ForEach(checkpointModelsManager.items.filter { $0.type == .coreMl }) { item in
              Button(item.name) {
                currentPrompt.selectedModel = item
                Debug.log("Selected CoreML Model: \(item.name)")
              }
            }
          }
          Section(header: Text("􁻴 Python")) {
            ForEach(checkpointModelsManager.items.filter { $0.type == .python }) { item in
              Button(item.name) {
                currentPrompt.selectedModel = item
                Debug.log("Selected Python Model: \(item.name)")
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
    }
    .disabled(!(scriptManager.modelLoadState == .idle || scriptManager.modelLoadState == .done))
    
    .onChange(of: currentPrompt.selectedModel) {
      if let checkpointModel = currentPrompt.selectedModel {
        Debug.log(".onChange(of: currentPrompt.selectedModel)")
        updateSelectedCheckpointModel(with: checkpointModel)
      }
    }
     
    
    .onChange(of: scriptManager.scriptState) {
      if scriptManager.scriptState == .active {
        Task {
          await checkpointModelsManager.loadModels()
        }
        // if user has already selected a checkpoint model, load that model
        if let checkpointModel = currentPrompt.selectedModel {
          Debug.log("User already selected model. Loading \(checkpointModel.name)")
          //updateSelectedCheckpointModel(with: checkpointModel)
        }
      }
    }

    .onChange(of: scriptManager.modelLoadState) {
      // if first load state done, promptViewHasLoadedInitialModel = true
      if scriptManager.modelLoadState == .done {
        promptViewHasLoadedInitialModel = true
      }
    }

    .onChange(of: checkpointModelsManager.hasLoadedInitialModelCheckpointsAndAssignedSdModel) {
      Debug.log("checkpointModelsManager.hasLoadedInitialModelCheckpointsAndAssignedSdModel: \(checkpointModelsManager.hasLoadedInitialModelCheckpointsAndAssignedSdModel)")
      if checkpointModelsManager.hasLoadedInitialModelCheckpointsAndAssignedSdModel {
        // if user hasn't yet selected a checkpoint model, fill the menu with the loaded model
        if currentPrompt.selectedModel == nil {
          Debug.log("User hasn't yet selected a model. Attempting to fill with API loaded model checkpoint...")
          Task {
            if let loadedCheckpointModel = await checkpointModelsManager.getModelCheckpointMatchingApiLoadedModelCheckpoint() {
              currentPrompt.selectedModel = loadedCheckpointModel
              Debug.log(" - apiLoadedModel: \(String(describing: loadedCheckpointModel.checkpointMetadata?.title))")
              Debug.log(" - currentPrompt.selectedModel: \(String(describing: currentPrompt.selectedModel?.checkpointMetadata?.title))")
            }
          }
        }
      }
    }
  }
}
*/

/*
extension CheckpointModelMenu {
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
    guard let checkpointMetadata = checkpointModel.checkpointApiModel else {
      return nil
    }
    
    Debug.log("[API] attempting to POST \(checkpointModel):\n > \(checkpointMetadata.title)")
    
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let requestBody = UpdateSdModelCheckpointRequest(sdModelCheckpoint: checkpointMetadata.title)
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


/*

extension CheckpointModelMenu {
  @MainActor
  /// Update automatic1111 currently loaded model checkpoint
  func updateAutomaticCheckpoint(forModel checkpointModel: CheckpointModel, apiUrl: URL, completion: @escaping (Result<String, UpdateModelError>) -> Void) {
    let endpoint = apiUrl.appendingPathComponent("/sdapi/v1/options")
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    guard let checkpointMetadata = checkpointModel.checkpointMetadata else {
      completion(.failure(.nilCheckpoint))
      return
    }
    
    Debug.log("[API] attempting to POST \(checkpointModel):\n > \(checkpointMetadata.title)")
    
    let requestBody = UpdateSdModelCheckpointRequest(sdModelCheckpoint: checkpointMetadata.title)
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
          completion(.success("Update successful for model: \(checkpointMetadata)."))
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

 */
 /*

#Preview {
  CommonPreviews.promptView
}
*/
