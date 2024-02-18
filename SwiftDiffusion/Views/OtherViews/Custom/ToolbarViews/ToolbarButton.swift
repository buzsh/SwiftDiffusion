//
//  ToolbarButton.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/10/24.
//

import SwiftUI

struct ToolbarButton: View {
  let text: String?
  let symbol: String?
  @Binding var isDisabled: Bool
  let action: () -> Void
  
  init(text: String? = nil, symbol: String? = nil, action: @escaping () -> Void) {
    self.text = text
    self.symbol = symbol
    self.action = action
    self._isDisabled = .constant(false)
  }
  
  var body: some View {
    Button(action: action) {
      Group {
        if let symbol = symbol {
          Image(systemName: symbol)
        } else if let text = text {
          Text(text)
        } else {
          EmptyView()
        }
      }
    }
    .disabled(isDisabled)
  }
}

#Preview {
  ToolbarButton(symbol: "arkit") {
    Debug.log("Hello")
  }
  .frame(width: 300, height: 40)
}
