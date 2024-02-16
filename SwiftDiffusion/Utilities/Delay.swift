//
//  Delay.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation

struct Delay {
  /// Perform an action after a set amount of seconds.
  static func by(_ seconds: Double, closure: @escaping () -> Void) {
    Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
      closure()
    }
  }
  
  static func repeatEvery(_ seconds: Double, closure: @escaping () -> Void) {
    Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { _ in
      closure()
    }
  }
}
