//
//  Constants.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

struct Constants {
  
  struct CommandLine {}
  struct Delays {}
  struct FileStructure {}
  struct FileTypes {}
  struct Layout {}
  struct Keys {}
  
}

extension Constants.CommandLine {
  static let zshPath = "/bin/zsh"
  static let zshUrl = URL(fileURLWithPath: zshPath)
}
