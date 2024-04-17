//
//  KeyCodes.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import Foundation

enum KeyCodes {
  case deleteKey
  
  var code: UInt16 {
    switch self {
    case .deleteKey: return 51
    }
  }
}
