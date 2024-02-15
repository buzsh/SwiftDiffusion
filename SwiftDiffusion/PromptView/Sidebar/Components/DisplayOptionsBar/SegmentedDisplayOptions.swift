//
//  SegmentedDisplayOptions.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/15/24.
//

import SwiftUI

struct ThemeConstants {
  var buttonItemWidth: CGFloat
  var buttonItemHeight: CGFloat
  var buttonCornerRadius: CGFloat
  var stackPadding: CGFloat
  var backgroundOpacity: CGFloat
  var overlayCornerRadius: CGFloat
  var overlayStrokeLineWidth: CGFloat
  var overlayStrokeOpacity: CGFloat
  var hoverBackgroundOpacity: CGFloat
  
  static func forTheme(_ colorScheme: ColorScheme) -> ThemeConstants {
    switch colorScheme {
    case .dark:
      return ThemeConstants(
        buttonItemWidth: 30.0,
        buttonItemHeight: 25.0,
        buttonCornerRadius: 10.0,
        stackPadding: 5.0,
        backgroundOpacity: 0.2,
        overlayCornerRadius: 15.0,
        overlayStrokeLineWidth: 1.2,
        overlayStrokeOpacity: 0.8,
        hoverBackgroundOpacity: 0.3)
    default:
      return ThemeConstants(
        buttonItemWidth: 30.0,
        buttonItemHeight: 25.0,
        buttonCornerRadius: 10.0,
        stackPadding: 5.0,
        backgroundOpacity: 0.1,
        overlayCornerRadius: 15.0,
        overlayStrokeLineWidth: 1.0,
        overlayStrokeOpacity: 0.7,
        hoverBackgroundOpacity: 0.2)
    }
  }
}

// Segmented Display Options View
struct SegmentedDisplayOptions: View {
  @Binding var noPreviewsItemButtonToggled: Bool
  @Binding var smallPreviewsButtonToggled: Bool
  @Binding var largePreviewsButtonToggled: Bool
  @Environment(\.colorScheme) var colorScheme
  
  @State private var isHovering = [false, false, false]
  
  private var constants: ThemeConstants {
    ThemeConstants.forTheme(colorScheme)
  }
  
  var body: some View {
    HStack {
      ForEach(0..<3, id: \.self) { index in
        Button(action: {
          withAnimation {
            noPreviewsItemButtonToggled = index == 0
            smallPreviewsButtonToggled = index == 1
            largePreviewsButtonToggled = index == 2
          }
        }) {
          Image(systemName: self.symbol(for: index))
            .foregroundColor(self.color(for: index))
        }
        .buttonStyle(BorderlessButtonStyle())
        .frame(width: constants.buttonItemWidth, height: constants.buttonItemHeight)
        .background(isHovering[index] ? Color.blue.opacity(constants.hoverBackgroundOpacity) : Color.clear)
        .cornerRadius(constants.buttonCornerRadius)
        .onHover { hovering in
          isHovering[index] = hovering
        }
      }
    }
    .padding(constants.stackPadding)
    .background(Color.gray.opacity(constants.backgroundOpacity))
    .clipShape(RoundedRectangle(cornerRadius: constants.overlayCornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: constants.overlayCornerRadius)
        .stroke(Color.secondary, lineWidth: constants.overlayStrokeLineWidth)
        .opacity(constants.overlayStrokeOpacity)
    )
  }
  
  private func symbol(for index: Int) -> String {
    switch index {
    case 0: return "list.bullet"
    case 1: return "square.fill.text.grid.1x2"
    case 2: return "text.below.photo"
    default: return ""
    }
  }
  
  private func color(for index: Int) -> Color {
    switch index {
    case 0: return noPreviewsItemButtonToggled ? .blue : .primary
    case 1: return smallPreviewsButtonToggled ? .blue : .primary
    case 2: return largePreviewsButtonToggled ? .blue : .primary
    default: return .primary
    }
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
