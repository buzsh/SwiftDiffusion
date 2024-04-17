//
//  CopyPasteUtility.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import Foundation
import AppKit

struct CopyPasteUtility {
  static func copyToClipboard(_ string: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(string, forType: .string)
  }
}
