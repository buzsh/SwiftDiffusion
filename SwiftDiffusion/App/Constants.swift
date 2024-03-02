//
//  Constants.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

struct Constants {
  
  struct Api {}
  struct App {}
  struct CommandLine {}
  struct Debug {}
  struct Delays {}
  struct FileStructure {}
  struct FileTypes {}
  struct Keys {}
  struct Layout {}
  struct Parsing {}
  struct PromptOptions {}
  struct Sidebar {}
  struct WindowSize {}
  
}

extension Constants.App {
  static let name = "SwiftDiffusion"
}

extension Constants.CommandLine {
  static let zshPath = "/bin/zsh"
  static let zshUrl = URL(fileURLWithPath: zshPath)
}
