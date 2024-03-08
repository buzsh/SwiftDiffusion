//
//  SidebarModel+Queue.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import Foundation

extension SidebarModel {
  func addToStorableSidebarItems(sidebarItem: SidebarItem, withImageUrls imageUrls: [URL]) {
    sidebarItem.imageUrls = imageUrls
    storableSidebarItems.append(sidebarItem)
  }
  
  func generatingSidebarItemFinished(withImageUrls imageUrls: [URL]) {
    guard let sidebarItem = currentlyGeneratingSidebarItem else {
      return
    }
    
    addToStorableSidebarItems(sidebarItem: sidebarItem, withImageUrls: imageUrls)
    currentlyGeneratingSidebarItem = nil
  }
}
