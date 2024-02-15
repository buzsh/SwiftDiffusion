//
//  SegmentedDisplayOptions.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/15/24.
//

import SwiftUI

struct SegmentedDisplayOptions: View {
  @Binding var noPreviewsItemButtonToggled: Bool
  @Binding var smallPreviewsButtonToggled: Bool
  @Binding var largePreviewsButtonToggled: Bool
  let itemWidth: CGFloat = Constants.Layout.SidebarToolbar.itemWidth
  let itemHeight: CGFloat = Constants.Layout.SidebarToolbar.itemHeight
  
  var body: some View {
    HStack {
      Button(action: {
        noPreviewsItemButtonToggled = true
        smallPreviewsButtonToggled = false
        largePreviewsButtonToggled = false
      }) {
        Image(systemName: "list.bullet")
          .foregroundColor(noPreviewsItemButtonToggled ? .blue : .primary)
      }
      .buttonStyle(BorderlessButtonStyle())
      .frame(width: itemWidth, height: itemHeight)
      .background(noPreviewsItemButtonToggled ? Color.blue.opacity(0.2) : Color.clear)
      .cornerRadius(10)
      
      Button(action: {
        noPreviewsItemButtonToggled = false
        smallPreviewsButtonToggled = true
        largePreviewsButtonToggled = false
      }) {
        Image(systemName: "square.fill.text.grid.1x2")
          .foregroundColor(smallPreviewsButtonToggled ? .blue : .primary)
      }
      .buttonStyle(BorderlessButtonStyle())
      .frame(width: itemWidth, height: itemHeight)
      .background(smallPreviewsButtonToggled ? Color.blue.opacity(0.2) : Color.clear)
      .cornerRadius(10)
      
      Button(action: {
        noPreviewsItemButtonToggled = false
        smallPreviewsButtonToggled = false
        largePreviewsButtonToggled = true
      }) {
        Image(systemName: "text.below.photo")
          .foregroundColor(largePreviewsButtonToggled ? .blue : .primary)
      }
      .buttonStyle(BorderlessButtonStyle())
      .frame(width: itemWidth, height: itemHeight)
      .background(largePreviewsButtonToggled ? Color.blue.opacity(0.2) : Color.clear)
      .cornerRadius(10)
    }
    .padding(5)
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 15))
    .overlay(
      RoundedRectangle(cornerRadius: 15)
        .stroke(Color.secondary, lineWidth: 1).opacity(0.7)
    )
  }
}

#Preview {
  @State var toggle1: Bool = false
  @State var toggle2: Bool = true
  @State var toggle3: Bool = false
  
  return SegmentedDisplayOptions(noPreviewsItemButtonToggled: $toggle1, smallPreviewsButtonToggled: $toggle2, largePreviewsButtonToggled: $toggle3)
    .frame(width: 200, height: 60)
}

#Preview("SidebarView") {
  SidebarView(
    selectedImage: .constant(MockDataController.shared.lastImage),
    lastSavedImageUrls: .constant(MockDataController.shared.mockImageUrls)
  )
  .modelContainer(MockDataController.shared.container)
  .environmentObject(PromptModel())
  .environmentObject(SidebarViewModel())
  .frame(width: 200)
}
