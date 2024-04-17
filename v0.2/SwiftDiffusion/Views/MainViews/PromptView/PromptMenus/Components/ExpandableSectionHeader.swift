//
//  ExpandableSectionHeader.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/24/24.
//

import SwiftUI

struct ExpandableSectionHeader: View {
  let title: String
  @Binding var isExpanded: Bool
  
  var body: some View {
    Button(action: {
      if isExpanded {
        withAnimation(.easeOut(duration: 0.2)) {
          self.isExpanded.toggle()
        }
      } else {
        withAnimation(.default) {
          self.isExpanded.toggle()
        }
      }
    }) {
      HStack(spacing: 0) {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
          .font(.system(size: 10, weight: .heavy))
          .frame(minWidth: 12)
          .foregroundStyle(.secondary)
        PromptRowHeading(title: title)
        Spacer()
      }
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  CommonPreviews.promptView
}
