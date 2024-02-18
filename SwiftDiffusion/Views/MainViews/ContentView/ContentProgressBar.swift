//
//  ContentProgressBar.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import SwiftUI

struct CustomLinearProgressViewStyle: ProgressViewStyle {
  @Environment(\.colorScheme) var colorScheme
  
  func makeBody(configuration: Configuration) -> some View {
    ProgressView(configuration)
      .shadow(radius: colorScheme == .dark ? 2 : 2)
  }
}

struct ContentProgressBar: View {
  @ObservedObject var scriptManager: ScriptManager
  @State private var launchStatusProgressBarValue: Double = -1
  
  var body: some View {
    VStack {
      if scriptManager.genStatus != .idle {
        ProgressView(value: scriptManager.genProgress)
          .progressViewStyle(CustomLinearProgressViewStyle())
          .frame(minWidth: 75, idealWidth: 120, maxWidth: 120)
        
        
      } else if launchStatusProgressBarValue < 0 {
        ProgressView(value: launchStatusProgressBarValue)
          .progressViewStyle(CustomLinearProgressViewStyle())
          .frame(minWidth: 75, idealWidth: 120, maxWidth: 120)
      }
    }
    .onChange(of: scriptManager.scriptState) {
      if scriptManager.scriptState == .launching {
        launchStatusProgressBarValue = -1
      } else {
        launchStatusProgressBarValue = 100
      }
    }
  }
  
  
}

#Preview {
  ContentProgressBar(scriptManager: ScriptManager.preview(withState: .active))
    .frame(width: 200, height: 80)
}
