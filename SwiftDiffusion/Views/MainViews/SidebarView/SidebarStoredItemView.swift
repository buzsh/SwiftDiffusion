//
//  SidebarStoredItemView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI

struct SidebarStoredItemView: View {
  let item: SidebarItem
  let smallPreviewsButtonToggled: Bool
  let largePreviewsButtonToggled: Bool
  let modelNameButtonToggled: Bool
  
  @State private var currentImageUrl: URL?
  
  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      if smallPreviewsButtonToggled {
        let fallbackImageUrl = item.imageUrls.last
        AsyncImage(url: currentImageUrl ?? fallbackImageUrl) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 50, height: 65)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black, radius: 1, x: 0, y: 1)
        } placeholder: {
          ProgressView()
        }
        .onAppear {
          currentImageUrl = item.imageThumbnailUrls?.last ?? fallbackImageUrl
        }
        .onChange(of: item.imageThumbnailUrls) {
          currentImageUrl = item.imageThumbnailUrls?.last ?? fallbackImageUrl
        }
      }
      
      VStack(alignment: .leading) {
        if largePreviewsButtonToggled {
          if let lastImageUrl = item.imageUrls.last {
            AsyncImage(url: lastImageUrl) { image in
              image
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black, radius: 1, x: 0, y: 1)
            } placeholder: {
              ProgressView()
            }
            .padding(.bottom, 8)
          }
        }
        
        Text(item.title)
          .lineLimit(modelNameButtonToggled ? 1 : 2)
        
        if modelNameButtonToggled, let modelName = item.prompt?.selectedModel?.name {
          Text(modelName)
            .font(.system(size: 10, weight: .light, design: .monospaced))
            .foregroundStyle(Color.secondary)
            .padding(.top, 1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
