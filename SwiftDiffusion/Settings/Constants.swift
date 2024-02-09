//
//  Constants.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

struct Constants {
  
  struct Api {}
  struct CommandLine {}
  struct Delays {}
  struct FileStructure {}
  struct FileTypes {}
  struct Keys {}
  struct Layout {}
  struct PromptOptions {}
  
}

extension Constants.CommandLine {
  static let zshPath = "/bin/zsh"
  static let zshUrl = URL(fileURLWithPath: zshPath)
}
