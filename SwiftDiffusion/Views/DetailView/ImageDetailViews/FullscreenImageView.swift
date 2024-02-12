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
    ZStack(alignment: .topTrailing) {
      Image(nsImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .edgesIgnoringSafeArea(.all)
      Button(action: onClose) {
        Image(systemName: "xmark.circle.fill")
          .font(.largeTitle)
          .padding()
      }
      .buttonStyle(BorderlessButtonStyle())
      .padding()
    }
  }
}

