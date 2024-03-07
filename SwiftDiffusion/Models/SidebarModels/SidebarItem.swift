//
//  SidebarItem.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/13/24.
//

import Foundation
import SwiftData

@Model class SidebarItem: Identifiable {
  @Attribute(.unique) var id: UUID = UUID()
  @Attribute var title: String
  @Attribute var timestamp: Date
  @Attribute var imageUrls: [URL]
  @Relationship(deleteRule: .cascade) var imageThumbnails: [ImageInfo]
  @Relationship(deleteRule: .cascade) var imagePreviews: [ImageInfo]
  @Relationship var prompt: StoredPromptModel?
  @Relationship var parent: SidebarFolder?
  
  init(title: String, timestamp: Date = Date(), imageUrls: [URL], prompt: StoredPromptModel? = nil, parent: SidebarFolder? = nil) {
    self.title = title
    self.timestamp = timestamp
    self.imageUrls = imageUrls
    self.imageThumbnails = []
    self.imagePreviews = []
    self.prompt = prompt
    self.parent = parent
  }
}

extension SidebarItem: Equatable {
  static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
    lhs.id == rhs.id
  }
}
