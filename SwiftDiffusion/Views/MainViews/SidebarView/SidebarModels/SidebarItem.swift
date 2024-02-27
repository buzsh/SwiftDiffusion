//
//  SidebarItem.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import Foundation
import SwiftData

@Model
class SidebarItem: Identifiable {
  @Attribute var id: UUID = UUID()
  @Attribute var title: String
  @Attribute var timestamp: Date
  @Attribute var imageUrls: [URL]
  @Relationship var imageThumbnails: [ImageInfo]
  @Relationship var imagePreviews: [ImageInfo]
  @Attribute var isWorkspaceItem: Bool = true
  @Relationship var prompt: StoredPromptModel?
  
  init(title: String, timestamp: Date = Date(), imageUrls: [URL], isWorkspaceItem: Bool, prompt: StoredPromptModel? = nil) {
    self.title = title
    self.timestamp = timestamp
    self.imageUrls = imageUrls
    self.imageThumbnails = []
    self.imagePreviews = []
    self.isWorkspaceItem = isWorkspaceItem
    self.prompt = prompt
  }
}

extension SidebarItem: Equatable {
  static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
    lhs.id == rhs.id
  }
}

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
