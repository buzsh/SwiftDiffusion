//
//  ConsoleView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI

struct ConsoleView: View {
  @ObservedObject var scriptManager: ScriptManager
  @Binding var scriptPathInput: String
  
  @State private var outputImage: Image?
  
  var body: some View {
    VStack {
      BrowseFileRow(placeholderText: "path/to/webui.sh",
                    textValue: $scriptPathInput) {
        await FilePickerService.browseForShellFile()
      }
                    .padding(.horizontal, Constants.Layout.verticalPadding)
                    .padding(.top, 10)
      // API test output
      if let outputImage = outputImage {
        outputImage
          .resizable()
          .scaledToFit()
      }
      
      TextEditor(text: $scriptManager.consoleOutput)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .font(.system(.body, design: .monospaced))
        .border(Color.gray.opacity(0.3), width: 1)
        .padding(.vertical, 10)
        .padding(.horizontal, Constants.Layout.verticalPadding)
      
      HStack {
        Circle()
          .fill(scriptManager.scriptState.statusColor)
          .frame(width: 10, height: 10)
          .padding(.trailing, 2)
        
        Text(scriptManager.scriptStateText)
          .font(.system(.body, design: .monospaced))
          .onAppear {
            scriptPathInput = scriptManager.scriptPath ?? ""
            Debug.log("Current script state: \(scriptManager.scriptStateText)")
          }
        
        if scriptManager.scriptState == .active, let url = scriptManager.serviceUrl {
          Button(action: {
            NSWorkspace.shared.open(url)
          }) {
            Image(systemName: "network")
          }
          .buttonStyle(.plain)
          .padding(.leading, 2)
        }
        
        if let url = scriptManager.serviceUrl {
          Button("Send API") {
            Task {
              await sendAPIRequest(api: url)
            }
          }
        }
        
        Spacer()
        
        Button(action: {
          scriptManager.terminateAllPythonProcesses {
            Debug.log("All Python processes terminated.")
          }
        }) {
          Image(systemName: "xmark.octagon")
        }
        .buttonStyle(.plain)
        .padding(.leading, 2)
        
        Button("Terminate") {
          ScriptManager.shared.terminate { result in
            switch result {
            case .success(let message):
              Debug.log("Process successfully terminated.\n > \(message)")
            case .failure(let error):
              Debug.log("Error: \(error.localizedDescription)")
            }
          }
        }
        .disabled(!scriptManager.scriptState.isTerminatable)
        
        Button("Start") {
          scriptManager.scriptPath = scriptPathInput
          scriptManager.run()
        }
        .disabled(!scriptManager.scriptState.isStartable)
      }
      .padding(.horizontal, Constants.Layout.verticalPadding)
    }
    .padding(14)
  }
  
  // https://github.com/AUTOMATIC1111/stable-diffusion-webui/discussions/3734
  func sendAPIRequest(api: URL) async {
    Debug.log("API base URL: \(api)")
    
    let endpoint = "sdapi/v1/txt2img"
    guard let url = URL(string: endpoint, relativeTo: api) else {
      Debug.log("Invalid URL")
      return
    }
    
    let payload: [String: Any] = [
      "prompt": "astronaut",
      "steps": 20
    ]
    //let payload = jsonPayload
    
    do {
      let requestData = try JSONSerialization.data(withJSONObject: payload, options: [])
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = requestData
      
      let (data, _) = try await URLSession.shared.data(for: request)
      
      // Parse the JSON response
      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
         let images = json["images"] as? [String], !images.isEmpty,
         let imageData = Data(base64Encoded: images[0]) {
        DispatchQueue.main.async {
          if let nsImage = NSImage(data: imageData) {
            self.outputImage = Image(nsImage: nsImage)
          }
        }
      }
    } catch {
      DispatchQueue.main.async {
        Debug.log("Request error: \(error)")
      }
    }
  }
}

let jsonPayload: [String: Any] = [
  "prompt": "astronaut",
  "steps": 20,
  "batch_size": 2
]
