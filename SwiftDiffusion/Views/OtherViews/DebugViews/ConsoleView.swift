//
//  ConsoleView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI

extension Constants.Layout {
  static let verticalPadding: CGFloat = 8
}

struct ConsoleView: View {
  @ObservedObject var userSettings = UserSettings.shared
  @ObservedObject var scriptManager = ScriptManager.shared
  @State private var outputImage: Image?
  
  var body: some View {
    VStack {
      BrowseFileRow(labelText: "webui.sh file",
                    placeholderText: "../stable-diffusion-webui/webui.sh",
                    textValue: $userSettings.webuiShellPath) {
        await FilePickerService.browseForShellFile()
      }
      .padding(.horizontal, Constants.Layout.verticalPadding)
      .padding(.top, 10)
      
      TextEditor(text: $scriptManager.consoleOutput)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .font(.system(.body, design: .monospaced))
        .border(Color.gray.opacity(0.3), width: 1)
        .padding(.bottom, 10)
        .padding(.horizontal, Constants.Layout.verticalPadding)
      
      HStack {
        Circle()
          .fill(scriptManager.scriptState.statusColor)
          .frame(width: 10, height: 10)
          .padding(.trailing, 2)
        
        Text(scriptManager.scriptStateText)
          .font(.system(.body, design: .monospaced))
          .onAppear {
            Debug.log("Current script state: \(scriptManager.scriptStateText)")
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
          scriptManager.run()
        }
        .disabled(!scriptManager.scriptState.isStartable)
      }
      .padding(.horizontal, Constants.Layout.verticalPadding)
    }
    //.padding(14)
    .padding(.horizontal, 4)
    .padding(.bottom, 10)
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
        Debug.log("[ConsoleView] Request error: \(error)")
      }
    }
  }
}

let jsonPayload: [String: Any] = [
  "prompt": "astronaut",
  "steps": 20,
  "batch_size": 2
]

#Preview {
  ConsoleView(userSettings: UserSettings.shared, scriptManager: ScriptManager.preview(withState: .active))
    .frame(width: 370)
}
