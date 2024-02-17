//
//  LoraModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/17/24.
//

import Foundation
import Combine

struct LoraModel: Identifiable, Decodable {
  var id = UUID()
  let name: String
  let alias: String
  let path: String
  
  enum CodingKeys: String, CodingKey {
    case name, alias, path
  }
}
