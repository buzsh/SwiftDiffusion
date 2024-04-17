//
//  DisplayOptionsBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/15/24.
//

import SwiftUI

extension Constants.Layout {
  struct SidebarToolbar {
    static let itemHeight: CGFloat = 20
    static let itemWidth: CGFloat = 30
    
    static let bottomBarHeight: CGFloat = 50
  }
}

struct DisplayOptionsBar: View {
  @EnvironmentObject var sidebarModel: SidebarModel
  
  var body: some View {
    VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
      .frame(height: Constants.Layout.SidebarToolbar.bottomBarHeight)
      .edgesIgnoringSafeArea(.bottom)
      .overlay(
        HStack {
          
          Spacer()
          
          HoverToggleButton(buttonToggled: $sidebarModel.modelNameButtonToggled, symbol: "arkit")
          
          Spacer()
          
          SegmentedDisplayOptions(
            noPreviewsItemButtonToggled: $sidebarModel.noPreviewsItemButtonToggled,
            smallPreviewsButtonToggled: $sidebarModel.smallPreviewsButtonToggled,
            largePreviewsButtonToggled: $sidebarModel.largePreviewsButtonToggled)
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
