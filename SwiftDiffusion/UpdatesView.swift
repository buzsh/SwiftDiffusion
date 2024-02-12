//
//  UpdatesView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct UpdatesView: View {
  var body: some View {
    VStack {
        ToggleWithLabel(isToggled: .constant(true), header: "Automatically check for updates", description: "Checks for new releases on GitHub", showAllDescriptions: true)
      
      Spacer()
      
      HStack {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Color.green)
        Text("You are running the latest version.")
          .bold()
      }

      Spacer()
      
      Button(action: {
        Debug.log("Button")
      }) {
        Text("Check for Updates")
      }
      .padding(.bottom, 10)
      
      Text("Last checked: Today, 2:34 PM")
        .font(.footnote)
        .foregroundStyle(Color.secondary)
    }
    .padding()
    .frame(width: 400, height: 250)
    
    .navigationTitle("Updates")
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        HStack {
          
          Button(action: {
            Debug.log("Button")
          }) {
            Image(systemName: "info.circle")
          }
          
        }
      }
    }
  }
  
}

#Preview {
  UpdatesView()
    .frame(width: 400, height: 250)
}

// MARK: ToggleWithLabel
struct ToggleWithLabel: View {
  @Binding var isToggled: Bool
  var header: String
  var description: String = ""
  @State private var isHovering = false
  var showAllDescriptions: Bool
  
  var body: some View {
    HStack(alignment: .top) {
      Toggle("", isOn: $isToggled)
        .padding(.trailing, 6)
        .padding(.top, 2)
      
      VStack(alignment: .leading) {
        HStack {
          Text(header)
            .font(.system(size: 14, weight: .regular, design: .default))
            .padding(.vertical, 2)
          if !showAllDescriptions {
            Image(systemName: "questionmark.circle")
              .onHover { isHovering in
                self.isHovering = isHovering
              }
          }
        }
        Text(description)
          .font(.system(size: 12))
          .foregroundStyle(Color.secondary)
          .opacity(showAllDescriptions || isHovering ? 1 : 0)
      }
      
    }
    .padding(.bottom, 8)
  }
}
