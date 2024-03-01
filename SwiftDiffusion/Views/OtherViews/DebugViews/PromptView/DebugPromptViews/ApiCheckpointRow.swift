//
//  ApiCheckpointRow.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/24/24.
//

import SwiftUI

struct ApiCheckpointRow: View {
  @ObservedObject var scriptManager = ScriptManager.shared
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  
  @State var loadedCheckpointName: String = "nil"
  @State private var isExpanded: Bool = false
  
  @State var mostRecentCheckpointPayload: String = "{}"
  
  @State private var isPrettyPrinted: Bool = false
  
  var body: some View {
    VStack {
      ExpandableSectionHeader(title: "API Model Checkpoint", isExpanded: $isExpanded)
      
      if isExpanded {
        VStack(alignment: .leading, spacing: 0) {
          VStack {
            HStack {
              Spacer()
              Text("Loaded Checkpoint: \(loadedCheckpointName)")
                .onChange(of: checkpointsManager.loadedCheckpointModel) {
                  if let checkpoint = checkpointsManager.loadedCheckpointModel {
                    loadedCheckpointName = checkpoint.name
                  } else {
                    loadedCheckpointName = "nil"
                  }
                }
              Spacer()
            }
            
            TextEditor(text: $mostRecentCheckpointPayload)
              .font(.system(size: 9, design: .monospaced))
              .frame(minHeight: 20, idealHeight: 40, maxHeight: 180)
              .border(Color.gray.opacity(0.5))
              .onChange(of: scriptManager.mostRecentApiRequestPayload) {
                formatJsonString()
              }
            
            HStack {
              Toggle("Pretty Print JSON", isOn: $isPrettyPrinted)
                .onChange(of: isPrettyPrinted) {
                  formatJsonString()
                }
            }
            
            if scriptManager.modelLoadErrorString != nil {
              
              Divider().foregroundStyle(Color.white)
              
              Text("Error will appear here")
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 4)
            }
          }
          .padding(.top, 4)
          .font(.system(size: 12, weight: .regular, design: .monospaced))
          .background(Color.black)
          .foregroundColor(.white)
        }
      }
      
    }
    .padding(.vertical, 10)
  }
  
  private func formatJsonString() {
    let jsonString = scriptManager.mostRecentApiRequestPayload
    
    if isPrettyPrinted {
      mostRecentCheckpointPayload = jsonString.prettyPrintedJSONString() ?? jsonString
    } else {
      mostRecentCheckpointPayload = jsonString.oneLineJSONString() ?? jsonString
    }
  }
}

#Preview {
  CommonPreviews.promptView
}

extension String {
  func prettyPrintedJSONString() -> String? {
    guard let data = self.data(using: .utf8) else { return nil }
    guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
          let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
          let prettyString = String(data: prettyData, encoding: .utf8) else { return nil }
    return prettyString
  }
  
  func oneLineJSONString() -> String? {
    guard let data = self.data(using: .utf8) else { return nil }
    guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
          let compactData = try? JSONSerialization.data(withJSONObject: object, options: []),
          let compactString = String(data: compactData, encoding: .utf8) else { return nil }
    return compactString
  }
}
