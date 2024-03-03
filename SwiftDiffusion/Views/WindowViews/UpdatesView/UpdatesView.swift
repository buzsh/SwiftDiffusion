//
//  UpdatesView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/12/24.
//

import SwiftUI

struct AppInfo {
  static var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
  }
  static var buildString: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
  }
  static var buildInt: Int {
    Int(buildString) ?? 0
  }
  static var versionAndBuild: String {
    "v\(version) (\(buildString))"
  }
}

struct UpdatesView: View {
  @EnvironmentObject var updateManager: UpdateManager
  @State private var showUpdateFrequencySection: Bool = false
  private let updateFrequencySectionHeight: CGFloat = 28
  private let initialFrameHeight: CGFloat = 250
  var expandedFrameHeight: CGFloat {
    initialFrameHeight + updateFrequencySectionHeight
  }
  
  var body: some View {
    VStack {
      
      ToggleWithLabel(isToggled: .constant(true), header: "Automatically check for updates", description: "Checks for new releases on GitHub", showAllDescriptions: true)
        .padding(.top, 10)
      
      if showUpdateFrequencySection {
        VStack {
          Menu {
            ForEach(UpdateFrequency.allCases, id: \.self) { frequency in
              Button(frequency.rawValue) {
                updateManager.updateCheckFrequency = frequency
                updateManager.saveSettings()
              }
            }
          } label: {
            Label(updateManager.updateCheckFrequency.rawValue, systemImage: "calendar")
          }
        }
        .frame(width: 250, height: updateFrequencySectionHeight)
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)))
      }
      
      Spacer()
      
      HStack(alignment: .top) {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Color.green)
          .padding(.trailing, 2)
        VStack(alignment: .leading) {
          Text("You are on the latest version.")
            .bold()
            .padding(.bottom, 1)
          Text("SwiftDiffusion \(AppInfo.versionAndBuild)")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
        }
      }
      
      Spacer()
      
      Button("Check for Updates") {
        Task {
          await updateManager.checkForUpdatesIfNeeded(force: true)
        }
      }
      .padding(.bottom, 10)
      .disabled(updateManager.isCheckingForUpdate)
      
      if let lastChecked = updateManager.lastCheckedTimestamp {
        Text("Last checked: \(lastChecked, formatter: itemFormatter)")
          .font(.footnote)
          .foregroundStyle(Color.secondary)
      } else {
        Text("Last checked: Never")
          .font(.footnote)
          .foregroundStyle(Color.secondary)
      }
      
      if let checkForUpdateError = updateManager.checkForUpdatesErrorMessage {
        Text(checkForUpdateError)
          .padding(.vertical, 4)
          .font(.footnote)
          .foregroundStyle(Color.red)
          .onAppear {
            Delay.by(7) { updateManager.checkForUpdatesErrorMessage = nil }
          }
      }
    }
    .padding()
    .frame(width: 400, height: showUpdateFrequencySection ? expandedFrameHeight : initialFrameHeight)
    .animation(.easeInOut, value: showUpdateFrequencySection)
    
    .navigationTitle("Updates")
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        HStack {
          
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.5)
            .opacity(updateManager.isCheckingForUpdate ? 1 : 0)
          
          Button(action: {
            withAnimation {
              showUpdateFrequencySection.toggle()
            }
          }) {
            Image(systemName: "clock")
              .foregroundStyle(showUpdateFrequencySection ? .blue : .secondary)
          }
          
        }
      }
    }
  }
  private var itemFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }
  
}

#Preview {
  let updateManager = UpdateManager()
  updateManager.loadSettings()
  
  return UpdatesView()
    .frame(idealWidth: 400, idealHeight: 250)
    .environmentObject(updateManager)
}

// MARK: ToggleWithLabel
struct ToggleWithLabel: View {
  @Binding var isToggled: Bool
  var header: String
  var description: String = ""
  @State private var isHovering = false
  var showAllDescriptions: Bool
  
  var body: some View {
    HStack(alignment: .top) {
      Toggle("", isOn: $isToggled)
        .padding(.trailing, 6)
        .padding(.top, 2)
      
      VStack(alignment: .leading) {
        HStack {
          Text(header)
            .font(.system(size: 14, weight: .regular, design: .default))
            .padding(.vertical, 2)
          if !showAllDescriptions {
            Image(systemName: "questionmark.circle")
              .onHover { isHovering in
                self.isHovering = isHovering
              }
          }
        }
        Text(description)
          .font(.system(size: 12))
          .foregroundStyle(Color.secondary)
          .opacity(showAllDescriptions || isHovering ? 1 : 0)
      }
      
    }
    .padding(.bottom, 8)
  }
}
