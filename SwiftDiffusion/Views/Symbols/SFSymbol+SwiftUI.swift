//
//  SFSymbol+SwiftUI.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI

extension SFSymbol {
  var name: String {
    return self.rawValue
  }
  
  var image: some View {
    Image(systemName: self.name)
  }
}
