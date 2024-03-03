//
//  BackgroundButtonStyles.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct StateColors {
  static let normalBlue = Color.blue
  static let pressedBlue = Color.blue.opacity(0.5)
  static let disabledGray = Color.gray.opacity(0.5)
  
  static let normalBorder = Color.secondary
  static let pressedBorder = Color.secondary.opacity(0.5)
}

extension StateColors {
  static let normalTextOpacity: Double = 1.0
  static let pressedTextOpacity: Double = 0.7
  static let disabledTextOpacity: Double = 0.5
}

extension StateColors {
  static let normalBorderOpacity: Double = 1.0
  static let pressedBorderOpacity: Double = 0.7
  static let disabledBorderOpacity: Double = 0.5
}

struct BlueBackgroundButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled: Bool
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.vertical, 6).padding(.horizontal, 10)
      .background(self.backgroundColor(for: configuration.isPressed))
      .foregroundColor(.white)
      .opacity(self.textOpacity(for: configuration.isPressed))
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(self.borderColor(for: configuration.isPressed), lineWidth: 1)
          .opacity(self.borderOpacity(for: configuration.isPressed)) // Adjust border opacity
      )
  }
  
  private func backgroundColor(for isPressed: Bool) -> Color {
    if !isEnabled {
      return StateColors.disabledGray
    } else {
      return isPressed ? StateColors.pressedBlue : StateColors.normalBlue
    }
  }
  
  private func borderColor(for isPressed: Bool) -> Color {
    return isEnabled ? StateColors.normalBlue : StateColors.disabledGray
  }
  
  private func textOpacity(for isPressed: Bool) -> Double {
    if !isEnabled {
      return StateColors.disabledTextOpacity
    } else {
      return isPressed ? StateColors.pressedTextOpacity : StateColors.normalTextOpacity
    }
  }
  
  private func borderOpacity(for isPressed: Bool) -> Double {
    if !isEnabled {
      return StateColors.disabledBorderOpacity
    } else {
      return isPressed ? StateColors.pressedBorderOpacity : StateColors.normalBorderOpacity
    }
  }
}

struct BorderBackgroundButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled: Bool
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(.vertical, 6).padding(.horizontal, 10)
      .foregroundColor(self.foregroundColor(for: configuration.isPressed))
      .opacity(self.textOpacity(for: configuration.isPressed))
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(self.borderColor(for: configuration.isPressed), lineWidth: 1)
          .opacity(self.borderOpacity(for: configuration.isPressed))
      )
  }
  
  private func foregroundColor(for isPressed: Bool) -> Color {
    if !isEnabled {
      return .gray
    } else {
      return isPressed ? StateColors.pressedBorder : StateColors.normalBorder
    }
  }
  
  private func borderColor(for isPressed: Bool) -> Color {
    return isEnabled ? StateColors.normalBorder : .gray
  }
  
  private func textOpacity(for isPressed: Bool) -> Double {
    if !isEnabled {
      return StateColors.disabledTextOpacity
    } else {
      return isPressed ? StateColors.pressedTextOpacity : StateColors.normalTextOpacity
    }
  }
  
  private func borderOpacity(for isPressed: Bool) -> Double {
    if !isEnabled {
      return StateColors.disabledBorderOpacity
    } else {
      return isPressed ? StateColors.pressedBorderOpacity : StateColors.normalBorderOpacity
    }
  }
}

#Preview {
  CommonPreviews.contentView
}
