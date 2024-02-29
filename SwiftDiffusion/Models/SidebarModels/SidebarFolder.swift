//
//  SidebarFolder.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import Foundation
import SwiftData

@Model
class SidebarFolder: Identifiable {
  @Attribute(.unique) var id: UUID = UUID()
  @Attribute var name: String
  @Attribute var timestamp: Date
  @Attribute var isRoot: Bool = false
  @Attribute var isWorkspace: Bool = false
  @Relationship var items: [SidebarItem]
  @Relationship var folders: [SidebarFolder]
  @Relationship var parent: SidebarFolder?
  
  init(name: String, timestamp: Date = Date(), isRoot: Bool = false, isWorkspace: Bool = false, items: [SidebarItem] = [], folders: [SidebarFolder] = [], parent: SidebarFolder? = nil) {
    self.name = name
    self.timestamp = timestamp
    self.isRoot = isRoot
    self.isWorkspace = isWorkspace
    self.items = items
    self.folders = folders
    self.parent = parent
  }
}

extension SidebarFolder: Equatable {
  static func == (lhs: SidebarFolder, rhs: SidebarFolder) -> Bool {
    lhs.name == rhs.name
  }
}

extension SidebarFolder {
  func add(item: SidebarItem) {
    self.items.append(item)
  }
  func add(folder: SidebarFolder) {
    folder.parent = self
    self.folders.append(folder)
  }
  func remove(item: SidebarItem) {
    self.items.removeAll(where: { $0.id == item.id })
  }
  func remove(folder: SidebarFolder) {
    self.folders.removeAll(where: { $0.id == folder.id })
  }
}

// MARK: DEPRECATED
extension SidebarFolder {
  func addItem(_ item: SidebarItem) {
    self.items.append(item)
  }
  
  func removeItem(_ item: SidebarItem) {
    self.items.removeAll { $0.id == item.id }
  }
  
  func removeItem(withId itemId: UUID) {
    self.items.removeAll { $0.id == itemId }
  }
}
