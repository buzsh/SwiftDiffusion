//
//  UserNotifications.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/11/24.
//

import Foundation
import UserNotifications

struct NotificationUtility {
  
  static func showCompletionNotification(imageCount: Int = 1) {
    var bodyText = "Your image has finished generating"
    
    if imageCount > 1 {
      bodyText = "\(imageCount) images have finished generating"
    }
    
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
      if granted {
        let content = UNMutableNotificationContent()
        content.title = "Swift Diffusion" // "Generation Complete"
        content.body = bodyText
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.add(request)
      }
    }
  }
  
}
