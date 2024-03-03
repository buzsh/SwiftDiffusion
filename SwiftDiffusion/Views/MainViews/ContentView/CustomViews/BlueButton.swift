//
//  BlueButton.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/2/24.
//

import SwiftUI

struct BlueButton: View {
  let title: String
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Text(title)
    }
    .buttonStyle(BlueBackgroundButtonStyle())
  }
}

struct OutlineButton: View {
  let title: String
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Text(title)
    }
    .buttonStyle(BorderBackgroundButtonStyle())
  }
}
