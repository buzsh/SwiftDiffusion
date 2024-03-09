//
//  FullscreenImageView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/11/24.
//

import SwiftUI

struct FullscreenImageView: View {
  var image: NSImage
  var onClose: () -> Void
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      Image(nsImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .edgesIgnoringSafeArea(.all)
      Button(action: onClose) {
        SFSymbol.closeFullscreen.image
          .font(.largeTitle)
          .padding()
      }
      .buttonStyle(BorderlessButtonStyle())
      .shadow(color: .black, radius: 10, x: 0, y: 4)
      .padding()
    }
  }
}
