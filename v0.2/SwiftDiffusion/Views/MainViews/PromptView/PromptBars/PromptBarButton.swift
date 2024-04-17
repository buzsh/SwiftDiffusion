//
//  PromptBarButton.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI

enum AlignSymbol {
  case leading, trailing
}

struct PromptBarButton: View {
  let title: String
  let symbol: SFSymbol
  var align: AlignSymbol = .leading
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      if align == .leading { symbol.image }
      Text(title)
      if align == .trailing { symbol.image }
    }
    .buttonStyle(.accessoryBar)
  }
}

#Preview {
  return HStack {
    PromptBarButton(title: "Close", symbol: .close, align: .leading, action: {
      
    })
    
    Spacer()
    
    PromptBarButton(title: "Save", symbol: .save, align: .trailing, action: {
      
    })
  }
  .padding()
  .frame(width: 400)
}
