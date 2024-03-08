//
//  ToolbarProgressView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI

struct ToolbarProgressView: View {
  @ObservedObject private var scriptManager = ScriptManager.shared
  
  var body: some View {
    if scriptManager.modelLoadState == .done && scriptManager.modelLoadTime > 0 {
      Text("\(String(format: "%.1f", scriptManager.modelLoadTime))s")
        .font(.system(size: 11, design: .monospaced))
        .padding(.trailing, 6)
    }
    
    if scriptManager.genStatus == .generating {
      Text("\(Int(scriptManager.genProgress * 100))%")
        .font(.system(.body, design: .monospaced))
    } else if scriptManager.genStatus == .finishingUp {
      Text("Saving")
        .font(.system(.body, design: .monospaced))
    } else if scriptManager.genStatus == .preparingToGenerate {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle())
        .scaleEffect(0.5)
    } else if scriptManager.genStatus == .done {
      Image(systemName: SFSymbol.checkmark.name)
    }
    
    if scriptManager.genStatus != .idle || scriptManager.scriptState == .launching {
      ContentProgressBar(scriptManager: scriptManager)
    }
  }
}
