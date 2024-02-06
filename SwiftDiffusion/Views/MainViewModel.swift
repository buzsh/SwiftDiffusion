//
//  MainViewModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Combine

class MainViewModel: ObservableObject {
  @Published var positivePrompt: String = ""
  @Published var negativePrompt: String = ""
}
