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
  @Relationship var items: [SidebarItem]
  @Relationship var folders: [SidebarFolder]
  
  init(name: String, items: [SidebarItem] = [], folders: [SidebarFolder] = []) {
    self.name = name
    self.items = items
    self.folders = folders
  }
}

extension SidebarFolder: Equatable {
  static func == (lhs: SidebarFolder, rhs: SidebarFolder) -> Bool {
    lhs.name == rhs.name
  }
}
