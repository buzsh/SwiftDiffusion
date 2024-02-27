//
//  SidebarFolder.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import Foundation
import SwiftData

@Model
class SidebarFolder {
  @Attribute var name: String
  @Relationship var contents: [SidebarItem]
  
  init(name: String, contents: [SidebarItem] = []) {
    self.name = name
    self.contents = contents
  }
}

extension SidebarFolder: Equatable {
  static func == (lhs: SidebarFolder, rhs: SidebarFolder) -> Bool {
    lhs.name == rhs.name
  }
}
