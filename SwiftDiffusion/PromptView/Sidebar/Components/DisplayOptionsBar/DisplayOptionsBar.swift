//
//  DisplayOptionsBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/15/24.
//

import SwiftUI

struct DisplayOptionsBar: View {
  @Binding var modelNameButtonToggled: Bool
  @Binding var noPreviewsItemButtonToggled: Bool
  @Binding var smallPreviewsButtonToggled: Bool
  @Binding var largePreviewsButtonToggled: Bool
  
  var body: some View {
    VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
      .frame(height: Constants.Layout.SidebarToolbar.bottomBarHeight)
      .edgesIgnoringSafeArea(.bottom)
      .overlay(
        HStack {
          
          Spacer()
          
          HoverToggleButton(buttonToggled: $modelNameButtonToggled, symbol: "arkit")
          
          Spacer()
          
          SegmentedDisplayOptions(
            noPreviewsItemButtonToggled: $noPreviewsItemButtonToggled,
            smallPreviewsButtonToggled: $smallPreviewsButtonToggled,
            largePreviewsButtonToggled: $largePreviewsButtonToggled)
          .padding(.trailing, 4)
          
          Spacer()
          
        }
      )
  }
}

#Preview {
  @State var toggle0: Bool = true
  @State var toggle1: Bool = false
  @State var toggle2: Bool = true
  @State var toggle3: Bool = false
  return DisplayOptionsBar(modelNameButtonToggled: $toggle0, noPreviewsItemButtonToggled: $toggle1, smallPreviewsButtonToggled: $toggle2, largePreviewsButtonToggled: $toggle3)
    .frame(width: 250)
}
