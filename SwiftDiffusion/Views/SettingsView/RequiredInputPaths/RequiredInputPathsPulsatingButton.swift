//
//  RequiredInputPathsPulsatingButton.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/11/24.
//

import SwiftUI

struct RequiredInputPathsPulsatingButton: View {
  @Binding var showingRequiredInputPathsView: Bool
  @Binding var hasDismissedRequiredInputPathsView: Bool
  @State private var isPulsating = false
  @State private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
  
  var body: some View {
    Button(action: {
      showingRequiredInputPathsView = true
      hasDismissedRequiredInputPathsView = false // reset dismissal tracking
    }) {
      Image(systemName: "exclamationmark.triangle")
        .scaleEffect(isPulsating ? 1.1 : 1.0)
        .foregroundColor(isPulsating ? .orange : .secondary)
    }
    .onAppear {
      triggerPulsation()
    }
    .onReceive(timer) { _ in
      triggerPulsation()
    }
  }
  
  private func triggerPulsation() {
    // reset to original state before starting animation
    self.isPulsating = false
    // start pulsation with a delay to allow for reset to take effect
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      withAnimation(Animation.easeInOut(duration: 1)) {
        self.isPulsating = true
      }
      // smoothly return to the initial state after the animation completes
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        withAnimation(Animation.easeInOut(duration: 1)) {
          self.isPulsating = false
        }
      }
    }
  }
}

#Preview {
  NavigationView {
    
  }.toolbar {
    ToolbarItemGroup(placement: .navigation) {
      RequiredInputPathsPulsatingButton(showingRequiredInputPathsView: .constant(false), hasDismissedRequiredInputPathsView: .constant(true))
    }
  }
}
