//
//  SymbolButtons.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI

struct MenuButton: View {
  let title: String
  var symbol: SFSymbol = .none
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        if symbol != .none {
          symbol.image
        }
        Text(title)
      }
    }
  }
}

struct SymbolButton: View {
  let symbol: SFSymbol
  let action: () -> Void
  
  var body: some View {
    Button(action: {
      action()
    }) {
      symbol.image
    }
    .buttonStyle(BorderlessButtonStyle())
  }
}

struct ToolbarSymbolButton: View {
  let title: String
  let symbol: SFSymbol
  let action: () -> Void
  
  var body: some View {
    Button(action: {
      action()
    }) {
      Label(title, systemImage: symbol.name)
    }
  }
}


struct SymbolButtons: View {
  var body: some View {
    VStack(spacing: 10) {
      MenuButton(title: "Test", symbol: .python, action: {})
      SymbolButton(symbol: .python, action: {})
    }
    .padding()
  }
}

#Preview {
  SymbolButtons()
}
