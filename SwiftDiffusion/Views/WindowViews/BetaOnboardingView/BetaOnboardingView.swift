//
//  WelcomeView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/2/24.
//

import SwiftUI

struct BetaOnboardingView: View {
  @ObservedObject var userSettings = UserSettings.shared
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    VStack {
      ScrollView {
        HStack {
          Spacer()
          Image("Logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 300)
          Spacer()
        }
        
        Text("Welcome to ")
      }
      HStack {
        Spacer()
        
        Button(action: {
          presentationMode.wrappedValue.dismiss()
        }) {
          Text("Done")
        }
        .padding(.horizontal, 6)
        .padding(.trailing,6)
      }
    }
    .navigationTitle("Getting Started")
    .toolbar {
      ToolbarItemGroup(placement: .primaryAction) {
        HStack {
          Spacer()
          
          Button(action: {
            presentationMode.wrappedValue.dismiss()
          }) {
            Text("Done")
          }
          
        }
      }
    }
  }
}

#Preview {
  BetaOnboardingView()
}
