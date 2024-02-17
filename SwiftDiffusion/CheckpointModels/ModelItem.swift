//
//  ModelItem.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import Foundation
import Combine

@MainActor
class CheckpointModel: ObservableObject, Identifiable {
  let id = UUID()
  let name: String
  let type: ModelType
  let url: URL
  var isDefaultModel: Bool = false
  var sdModel: SdModel?

  @Published var preferences: ModelPreferences
  
  init(name: String, type: ModelType, url: URL, isDefaultModel: Bool = false, sdModel: SdModel? = nil) {
    self.name = name
    self.type = type
    self.url = url
    self.isDefaultModel = isDefaultModel
    self.sdModel = sdModel
    self.preferences = ModelPreferences.defaultSamplingForModelType(type: type)
  }
  
  func setSdModel(_ model: SdModel) {
    self.sdModel = model
  }
}

enum ModelType {
  case coreMl
  case python
}

extension CheckpointModel: Equatable {
  static func == (lhs: ModelItem, rhs: ModelItem) -> Bool {
    return lhs.id == rhs.id
  }
}
