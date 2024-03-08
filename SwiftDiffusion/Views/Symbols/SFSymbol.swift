//
//  SFSymbol.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import Foundation

enum SFSymbol: String {
  case coreMl = "rotate.3d"
  case python = "point.bottomleft.forward.to.point.topright.scurvepath"
  case network
  case arkit
  case gear
  
  case play = "play.fill"
  case stop = "stop.fill"
  case bonjour
  case trash
  case lock
  
  case folder
  
  case checkmark
  case pencil
  
  case newFolder = "folder.badge.plus"
  case newPrompt = "plus.bubble"
  
  case upDirectory = "arrow.turn.left.up"
  
  case copy = "clipboard"
  case paste = "arrow.up.doc.on.clipboard"
  
  case close = "xmark"
  case save = "square.and.arrow.down"
  case copyToWorkspace = "tray.and.arrow.up"
  
  case shuffle
  case repeatLast = "repeat"
  
  // Detail
  case photo
  case back = "arrow.left"
  case forward = "arrow.right"
  case refresh = "arrow.clockwise"
  case mostRecent = "clock.arrow.circlepath"
  case fullscreen = "arrow.up.left.and.arrow.down.right"
  case share = "square.and.arrow.up"
  
  case none
}
