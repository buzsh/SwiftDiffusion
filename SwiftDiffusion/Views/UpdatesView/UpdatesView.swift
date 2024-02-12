//
//  UpdatesView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct AppInfo {
  static var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
  }
  
  static var buildString: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
  }
  
  static var buildInt: Int {
    Int(buildString) ?? 0
  }
  
  static var versionAndBuild: String {
    "v\(version) (\(buildString))"
  }
}

struct UpdatesView: View {
  
  var body: some View {
    VStack {
      ToggleWithLabel(isToggled: .constant(true), header: "Automatically check for updates", description: "Checks for new releases on GitHub", showAllDescriptions: true)
      
      Spacer()
      
      HStack(alignment: .top) {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Color.green)
          .padding(.trailing, 2)
        VStack(alignment: .leading) {
          Text("You are running the latest version.")
            .bold()
            .padding(.bottom, 1)
          Text("SwiftDiffusion \(AppInfo.versionAndBuild)")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
        }
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
          
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.5)
          
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
