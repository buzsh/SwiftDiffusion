//
//  DisplayOptionsBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/15/24.
//

import SwiftUI

struct DisplayOptionsBar: View {
  @EnvironmentObject var sidebarViewModel: SidebarViewModel
  
  var body: some View {
    VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
      .frame(height: Constants.Layout.SidebarToolbar.bottomBarHeight)
      .edgesIgnoringSafeArea(.bottom)
      .overlay(
        HStack {
          
          Spacer()
          
          HoverToggleButton(buttonToggled: $sidebarViewModel.modelNameButtonToggled, symbol: "arkit")
          
          Spacer()
          
          SegmentedDisplayOptions(
            noPreviewsItemButtonToggled: $sidebarViewModel.noPreviewsItemButtonToggled,
            smallPreviewsButtonToggled: $sidebarViewModel.smallPreviewsButtonToggled,
            largePreviewsButtonToggled: $sidebarViewModel.largePreviewsButtonToggled)
          .padding(.trailing, 4)
          
          Spacer()
          
        }
      )
  }
}

/*
#Preview {
  @State var toggle0: Bool = true
  @State var toggle1: Bool = false
  @State var toggle2: Bool = true
  @State var toggle3: Bool = false
  return DisplayOptionsBar(modelNameButtonToggled: $toggle0, noPreviewsItemButtonToggled: $toggle1, smallPreviewsButtonToggled: $toggle2, largePreviewsButtonToggled: $toggle3)
    .frame(width: 250)
}
*/
