//
//  FileRowView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct FileRowView: View {
  let node: FileNode
  @StateObject private var thumbnailLoader = ThumbnailLoader()
  
  var body: some View {
    HStack {
      if let thumbnailImage = thumbnailLoader.thumbnailImage {
        Image(nsImage: thumbnailImage)
          .resizable()
          .scaledToFit()
          .frame(width: 20, height: 20)
      } else {
        ProgressView()
          .frame(width: 20, height: 20)
      }
      
      Text(node.name)
      
      Spacer()
      
      // Display the dimensions and file size if available
      if let size = thumbnailLoader.imageSize {
        let width = Int(size.width)
        let height = Int(size.height)
        let dimensionString = "\(width)x\(height)"
        let fileSizeString = thumbnailLoader.fileSize
        
        Text("\(fileSizeString)  •  \(dimensionString)")
          .font(.caption)
          .foregroundColor(.gray)
      }
    }
    .task {
      await thumbnailLoader.loadThumbnail(for: node)
    }
  }
}
