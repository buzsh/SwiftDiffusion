//
//  StoredVaeModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import Foundation
import SwiftData

@Model
class StoredVaeModel {
  @Attribute var name: String
  @Attribute var path: String
  
  init(name: String, path: String) {
    self.name = name
    self.path = path
  }
}

extension MapModelData {
  
  @MainActor
  func toStoredVaeModel(from vaeModel: VaeModel?) -> StoredVaeModel? {
    guard let vaeModel = vaeModel else { return nil }
    return StoredVaeModel(name: vaeModel.name,
                          path: vaeModel.path
    )
  }

  @MainActor
  func toVaeModel(from storedVaeModel: StoredVaeModel?) -> VaeModel? {
    guard let storedVaeModel = storedVaeModel else { return nil }
    
    return VaeModel(name: storedVaeModel.name,
                    path: storedVaeModel.path
    )
  }
  
}
