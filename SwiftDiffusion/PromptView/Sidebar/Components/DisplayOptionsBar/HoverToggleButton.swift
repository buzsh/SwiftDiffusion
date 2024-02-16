//
//  HoverButton.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/15/24.
//

import SwiftUI

// Constants for HoverToggleButton customization
private struct HoverToggleButtonConstants {
  static let defaultSymbol: String = "arkit"
  static let itemWidth: CGFloat = 30.0
  static let itemHeight: CGFloat = 30.0
  static let cornerRadius: CGFloat = 10.0
  static let hoverBackgroundOpacity: CGFloat = 0.2
  static let nonHoverBackgroundOpacity: CGFloat = 0.0
  static let paddingLeading: CGFloat = 4.0
}

struct HoverToggleButton: View {
  @Binding var buttonToggled: Bool
  var symbol: String = HoverToggleButtonConstants.defaultSymbol
  let itemWidth: CGFloat = HoverToggleButtonConstants.itemWidth
  let itemHeight: CGFloat = HoverToggleButtonConstants.itemHeight
  @State private var isHovering: Bool = false
  
  var body: some View {
    Button(action: {
      buttonToggled.toggle()
    }) {
      Image(systemName: symbol)
        .foregroundColor(buttonToggled ? .blue : .primary)
    }
    .buttonStyle(BorderlessButtonStyle())
    .frame(width: itemWidth, height: itemHeight)
    .background(isHovering ? RoundedRectangle(cornerRadius: HoverToggleButtonConstants.cornerRadius).fill(Color.gray.opacity(HoverToggleButtonConstants.hoverBackgroundOpacity)) : RoundedRectangle(cornerRadius: HoverToggleButtonConstants.cornerRadius).fill(Color.clear.opacity(HoverToggleButtonConstants.nonHoverBackgroundOpacity)))
    .clipShape(RoundedRectangle(cornerRadius: HoverToggleButtonConstants.cornerRadius))
    .padding(.leading, HoverToggleButtonConstants.paddingLeading)
    .onHover { hovering in
      isHovering = hovering
    }
  }
}


#Preview {
  @State var toggle: Bool = true
  return HoverToggleButton(buttonToggled: $toggle)
    .frame(width: 100, height: 40)
}
