//
//  ProgressViewModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import SwiftUI

class ProgressViewModel: ObservableObject {
  @Published var progress: Double = 0 {
    didSet {
      Debug.log("Progress updated to \(progress)")
    }
  }
}
