//
//  ShareButton.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/26/24.
//

import SwiftUI

struct ShareButton: View {
  @Binding var selectedImage: NSImage?
  
  var body: some View {
    DetailToolbarSymbolButton(hint: "Share Image", symbol: .share, action: {
      if let image = selectedImage {
        SharePickerCoordinator.shared.showSharePicker(for: image)
      }
    })
    .disabled(selectedImage == nil)
  }
}

#Preview {
  CommonPreviews.detailView
}

class SharePickerCoordinator: NSObject, NSSharingServicePickerDelegate {
  static let shared = SharePickerCoordinator()
  
  func showSharePicker(for image: NSImage) {
    let sharingServicePicker = NSSharingServicePicker(items: [image])
    sharingServicePicker.delegate = self
    
    if let window = NSApp.keyWindow {
      sharingServicePicker.show(relativeTo: CGRect(x: window.frame.width / 2, y: window.frame.height / 2, width: 0, height: 0), of: window.contentView!, preferredEdge: .minY)
    }
  }
}

struct SharePickerRepresentable: NSViewRepresentable {
  @Binding var showingSharePicker: Bool
  @Binding var selectedImage: NSImage?
  
  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    return view
  }
  
  func updateNSView(_ nsView: NSView, context: Context) {
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, NSSharingServicePickerDelegate {
    var parent: SharePickerRepresentable
    
    init(_ parent: SharePickerRepresentable) {
      self.parent = parent
    }
    
    func share() {
      guard let image = parent.selectedImage else { return }
      let sharingServicePicker = NSSharingServicePicker(items: [image])
      sharingServicePicker.delegate = self
      
      if let window = NSApp.keyWindow {
        sharingServicePicker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
      }
      
      DispatchQueue.main.async {
        self.parent.showingSharePicker = false
      }
    }
  }
}
