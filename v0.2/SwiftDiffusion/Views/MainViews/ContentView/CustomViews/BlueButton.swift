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
        .font(.system(size: 13, weight: .semibold))
    }
    .buttonStyle(BlueBackgroundButtonStyle())
  }
}

struct BlueSymbolButton: View {
  let title: String
  let symbol: SFSymbol
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
        Image(systemName: symbol.name)
      }
      .font(.system(size: 13, weight: .medium))
      .padding(.horizontal, 3)
    }
    .buttonStyle(BlueBackgroundSmallButtonStyle())
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
