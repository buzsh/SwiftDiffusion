//
//  DetailToolbarSymbolButton.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI

extension Constants.Layout {
  struct Toolbar {
    static let itemHeight: CGFloat = 30
    static let itemWidth: CGFloat = 30
  }
}

struct DetailToolbarSymbolButton: View {
  var hint: String = ""
  let symbol: SFSymbol
  let action: () -> Void
  
  private let itemHeight: CGFloat = 30
  private let itemWidth: CGFloat = 30
  
  var body: some View {
    Button(action: action) {
      symbol.image
    }
    .buttonStyle(BorderlessButtonStyle())
    .frame(width: Constants.Layout.Toolbar.itemWidth, height: Constants.Layout.Toolbar.itemHeight)
    .help(hint)
  }
}

#Preview {
  CommonPreviews.detailView
}
