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
  var selectedBackgroundOpacity: CGFloat = 0.2
  var nonSelectedHoverBackgroundOpacity: CGFloat = 0.2
  var selectedBackgroundColor: Color = Color.blue
  var nonSelectedHoverBackgroundColor: Color = Color.gray
  var strokeColor: Color = Color.secondary
  
  static func forTheme(_ colorScheme: ColorScheme) -> ThemeConstants {
    switch colorScheme {
    case .dark:
      return ThemeConstants(
        buttonItemWidth: 30.0,
        buttonItemHeight: 25.0,
        buttonCornerRadius: 10.0,
        stackPadding: 5.0,
        backgroundOpacity: 0.1,
        overlayCornerRadius: 15.0,
        overlayStrokeLineWidth: 1.2,
        overlayStrokeOpacity: 1,
        hoverBackgroundOpacity: 0.3,
        selectedBackgroundOpacity: 0.1,
        nonSelectedHoverBackgroundOpacity: 0.5,
        selectedBackgroundColor: Color.blue,
        nonSelectedHoverBackgroundColor: Color.gray.opacity(0.5),
        strokeColor: Color.secondary.opacity(0.8))
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
        hoverBackgroundOpacity: 0.2,
        selectedBackgroundOpacity: 0.2,
        nonSelectedHoverBackgroundOpacity: 0.5,
        selectedBackgroundColor: Color.blue,
        nonSelectedHoverBackgroundColor: Color.gray.opacity(0.5),
        strokeColor: Color.secondary.opacity(0.5))
    }
  }
}

enum SegmentedSelectedItemStyle {
  case overlay, outline
}

struct SegmentedDisplayOptions: View {
  @Binding var noPreviewsItemButtonToggled: Bool
  @Binding var smallPreviewsButtonToggled: Bool
  @Binding var largePreviewsButtonToggled: Bool
  @Environment(\.colorScheme) var colorScheme
  
  var selectedItemStyle: SegmentedSelectedItemStyle? = .outline
  
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
        .background(self.backgroundColor(for: index))
        .overlay(self.selectedItemOverlay(for: index))
        .cornerRadius(constants.buttonCornerRadius)
        .onHover { hovering in
          if !self.isSelected(index: index) {
            isHovering[index] = hovering
          }
        }
      }
    }
    .padding(constants.stackPadding)
    .background(Color.gray.opacity(constants.backgroundOpacity))
    .clipShape(RoundedRectangle(cornerRadius: constants.overlayCornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: constants.overlayCornerRadius)
        .stroke(constants.strokeColor, lineWidth: constants.overlayStrokeLineWidth)
        .opacity(constants.overlayStrokeOpacity)
    )
  }
  
  private func isSelected(index: Int) -> Bool {
    switch index {
    case 0: return noPreviewsItemButtonToggled
    case 1: return smallPreviewsButtonToggled
    case 2: return largePreviewsButtonToggled
    default: return false
    }
  }
  
  private func backgroundColor(for index: Int) -> Color {
    if isSelected(index: index) {
      return constants.selectedBackgroundColor.opacity(constants.selectedBackgroundOpacity)
    } else {
      return isHovering[index] ? constants.nonSelectedHoverBackgroundColor.opacity(constants.nonSelectedHoverBackgroundOpacity) : Color.clear
    }
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
  
  private func selectedItemOverlay(for index: Int) -> some View {
    GeometryReader { geometry in
      if isSelected(index: index) && selectedItemStyle == .outline {
        RoundedRectangle(cornerRadius: constants.buttonCornerRadius)
          .stroke(constants.selectedBackgroundColor, lineWidth: constants.overlayStrokeLineWidth)
          .opacity(constants.overlayStrokeOpacity)
          .frame(width: geometry.size.width, height: geometry.size.height)
      }
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
