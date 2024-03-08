//
//  SegmentedViewPicker.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI

enum ViewManager {
  case prompt, console, split
  
  var title: String {
    switch self {
    case .prompt: return "Prompt"
    case .console: return "Console"
    case .split: return "Split"
    }
  }
}

extension ViewManager: Hashable, Identifiable {
  var id: Self { self }
}

struct SegmentedViewPicker: View {
  @Binding var selectedView: ViewManager
  
  var body: some View {
    Picker("Options", selection: $selectedView) {
      Text("Prompt").tag(ViewManager.prompt)
      Text("Console").tag(ViewManager.console)
      Text("Split").tag(ViewManager.split)
    }
    .pickerStyle(SegmentedPickerStyle())
  }
}
