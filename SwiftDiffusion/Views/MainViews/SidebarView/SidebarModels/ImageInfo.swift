//
//  ImageInfo.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import Foundation
import SwiftData

@Model
class ImageInfo: Identifiable {
  @Attribute var id: UUID = UUID()
  @Attribute var url: URL
  @Attribute var width: CGFloat
  @Attribute var height: CGFloat
  
  init(url: URL, width: CGFloat, height: CGFloat) {
    self.url = url
    self.width = width
    self.height = height
  }
}
