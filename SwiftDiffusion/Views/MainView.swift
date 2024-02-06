//
//  MainView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI

extension Constants.Layout {
  static let listViewPadding: CGFloat = 12
  static let listViewResizableBarPadding = listViewPadding - halfResizableBarWidth
  
  static let resizableBarWidth: CGFloat = 10
  static let halfResizableBarWidth: CGFloat = resizableBarWidth/2
}

struct MainView: View {
  @ObservedObject var prompt: MainViewModel
  @State private var columnWidth: CGFloat = 200
  let minColumnWidth: CGFloat = 160
  let minSecondColumnWidth: CGFloat = 160
  
  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        // Column 1
        VStack {
          ScrollView {
            Form {
              PromptEditorView(label: "Positive Prompt", text: $prompt.positivePrompt)
              PromptEditorView(label: "Negative Prompt", text: $prompt.negativePrompt)
              
              Text("Model")
                .textCase(.uppercase)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .opacity(0.8)
                .padding(.horizontal, 8)
              Menu {
                Section("CoreML") {
                  Button("First") {  }
                  Button("Second") {  }
                }
                
                Section("Python") {
                  Button("First") {  }
                  Button("Second") {  }
                }
                
              } label: {
                Label("Menu", systemImage: "ellipsis.circle")
              }
            }
            .padding(.vertical, Constants.Layout.listViewPadding)
            .padding(.leading, Constants.Layout.listViewPadding)
            .padding(.trailing, Constants.Layout.listViewResizableBarPadding)
            Spacer()
          }
          
          Divider()
            .padding(.horizontal, 20)
          
          VStack {
            Button("Generate") { }
          }
          .padding(.bottom, 6)
        }
        .frame(width: columnWidth)
        
        // Adjustable bar
        Divider()
          .frame(width: 10)
          .background(Color.primary.opacity(0.0001))
          .padding(.vertical, 14)
          .gesture(
            DragGesture()
              .onChanged { value in
                let maxColumnWidth = geometry.size.width - minSecondColumnWidth - 10
                let dragAdjustedWidth = columnWidth + value.translation.width
                columnWidth = min(max(dragAdjustedWidth, minColumnWidth), maxColumnWidth)
              }
          )
        
        // Column 2
        VStack {
          Text("Resizable column 2")
          Spacer()
        }
        .padding()
        .frame(minWidth: minSecondColumnWidth, maxWidth: .infinity)
        .background(VisualEffectBlurView(material: .headerView, blendingMode: .behindWindow))
      }
    }
    .frame(minWidth: 300)
  }
}


#Preview("Left Prompt View") {
  let promptModel = MainViewModel()
  promptModel.positivePrompt = "sample, positive, prompt"
  promptModel.negativePrompt = "sample, negative, prompt"
  
  return MainView(prompt: promptModel)
}


extension NSTextView {
  open override var frame: CGRect {
    didSet {
      backgroundColor = .clear
      drawsBackground = true
    }
    
  }
}


import SwiftUI
import AppKit

struct VisualEffectBlurView: NSViewRepresentable {
  var material: NSVisualEffectView.Material
  var blendingMode: NSVisualEffectView.BlendingMode
  
  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
    return view
  }
  
  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
  }
}
