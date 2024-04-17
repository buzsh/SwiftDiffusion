//
//  SoundUtility.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/18/24.
//

import AppKit
import AVFoundation

struct SoundUtility {
  
  static func play(systemSound: SystemSound) {
    if let sound = NSSound(contentsOfFile: systemSound.path, byReference: true) {
      sound.play()
    } else {
      Debug.log("Failed to play system sound")
    }
  }
  
}

enum SystemSound {
  case trash, poof, mount, unmount
  
  var path: String {
    switch self {
    case .trash: return "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/dock/drag to trash.aif"
    case .poof: return "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/dock/poof item off dock.aif"
    case .mount: return "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Volume Mount.aif"
    case .unmount: return "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Volume Mount.aif"
    }
  }
}
