//
//  Dividers.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI

struct HorizontalDivider: View {
  var lightColor: Color = .gray.opacity(0.25)
  var darkColor: Color = .black
  var thickness: CGFloat = 1
  
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    Rectangle()
      .fill(currentColor)
      .frame(height: thickness)
      .edgesIgnoringSafeArea(.all)
  }
  
  private var currentColor: Color {
    colorScheme == .dark ? darkColor : lightColor
  }
}

struct VerticalDivider: View {
  var lightColor: Color = .gray.opacity(0.25)
  var darkColor: Color = .black
  var thickness: CGFloat = 1
  
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    Rectangle()
      .fill(currentColor)
      .frame(width: thickness)
      .edgesIgnoringSafeArea(.all)
  }
  
  private var currentColor: Color {
    colorScheme == .dark ? darkColor : lightColor
  }
}

#Preview {
  CommonPreviews.detailView
}
