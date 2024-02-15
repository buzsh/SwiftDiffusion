//
//  HoverButton.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/15/24.
//

import SwiftUI

struct HoverToggleButton: View {
  @Binding var buttonToggled: Bool
  var symbol: String = "arkit"
  let itemWidth: CGFloat = Constants.Layout.SidebarToolbar.itemWidth
  let itemHeight: CGFloat = Constants.Layout.SidebarToolbar.itemHeight
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
    .background(isHovering ? RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)) : RoundedRectangle(cornerRadius: 10).fill(Color.clear))
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .padding(.leading, 4)
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
