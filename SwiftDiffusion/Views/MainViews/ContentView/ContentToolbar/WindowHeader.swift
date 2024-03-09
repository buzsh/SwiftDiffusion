//
//  WindowHeader.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI

struct WindowToolbarTitle: View {
  let text: String
  
  var body: some View {
    Text(text)
      .font(.system(size: 15, weight: .semibold, design: .default))
  }
}

struct ContentViewToolbarTitle: View {
  let text: String
  @ObservedObject private var pastableService = PastableService.shared
  @ObservedObject private var userSettings = UserSettings.shared
  
  var body: some View {
    if pastableService.canPasteData == false && userSettings.showDeveloperInterface == false {
      WindowToolbarTitle(text: text)
    }
  }
}
