//
//  DetailImageView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/8/24.
//

import SwiftUI
import AppKit

struct DetailImageView: View {
  @Binding var image: NSImage?
  
  var body: some View {
    VStack {
      if let image = image {
        Image(nsImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
      } else {
        Spacer()
        HStack {
          Spacer()
          SFSymbol.photo.image
            .font(.system(size: 30, weight: .light))
            .foregroundColor(Color.secondary)
            .opacity(0.5)
          Spacer()
        }
        Spacer()
      }
    }
  }
}

#Preview {
  CommonPreviews.detailView
}
