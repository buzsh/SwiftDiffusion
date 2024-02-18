//
//  ToggleWithHeader.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct ToggleWithHeader: View {
  @Binding var isToggled: Bool
  var header: String
  var description: String = ""
  @State private var isHovering = false
  var showAllDescriptions: Bool
  
  var body: some View {
    HStack(alignment: .top) {
      Toggle("", isOn: $isToggled)
        .padding(.trailing, 6)
        .frame(width: 60)
        .toggleStyle(SwitchToggleStyle(tint: .blue))
      
      VStack(alignment: .leading) {
        HStack {
          Text(header)
            .font(.system(size: 14, weight: .semibold, design: .default))
            .underline()
            .padding(.vertical, 2)
          Image(systemName: "questionmark.circle")
            .onHover { isHovering in
              self.isHovering = isHovering
            }
        }
        Text(description)
          .font(.system(size: 12))
          .foregroundStyle(Color.secondary)
          .opacity(showAllDescriptions || isHovering ? 1 : 0)
      }
      
      Spacer()
    }
    .padding(.bottom, 8)
  }
}

#Preview {
  SettingsView(selectedTab: .prompt)
}
