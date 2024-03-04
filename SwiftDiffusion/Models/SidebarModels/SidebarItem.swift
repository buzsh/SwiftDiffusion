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
  @Attribute(.unique) var id: UUID = UUID()
  @Relationship var parent: SidebarFolder
  @Attribute var title: String
  @Attribute var timestamp: Date
  @Attribute var imageUrls: [URL]
  @Relationship var imageThumbnails: [ImageInfo]
  @Relationship var imagePreviews: [ImageInfo]
  //@Relationship var prompt: StoredPromptModel?
  @Relationship(deleteRule: .cascade, inverse: \SidebarItem.parent) var prompt: StoredPromptModel
  
  init(parent: SidebarFolder, title: String, timestamp: Date = Date(), imageUrls: [URL], prompt: StoredPromptModel) {
    self.parent = parent
    self.title = title
    self.timestamp = timestamp
    self.imageUrls = imageUrls
    self.imageThumbnails = []
    self.imagePreviews = []
    self.prompt = prompt
  }
}

extension SidebarItem: Equatable {
  static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
    lhs.id == rhs.id
  }
}
