//
//  HalfMaxWidthView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI

struct HalfMaxWidthView<Content: View>: View {
  let content: Content
  
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
  
  var body: some View {
    GeometryReader { geometry in
      content
        .frame(width: geometry.size.width / 2)
    }
  }
}
