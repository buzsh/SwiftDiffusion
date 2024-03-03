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

enum UpdateViewState {
  case defaultState
  case latestVersion
  case checkingForUpdate
  case newVersionAvailable
  
  var statusText: String {
    switch self {
    case .defaultState: "Haven't checked for updates."
    case .latestVersion: "You are on the latest version."
    case .checkingForUpdate: "Checking for new update..."
    case .newVersionAvailable: "There's a new version available!"
    }
  }
  
  var symbol: String {
    switch self {
    case .defaultState: "icloud.slash.fill"
    case .latestVersion: "checkmark.circle.fill"
    case .checkingForUpdate: "arrow.triangle.2.circlepath.icloud.fill"
    case .newVersionAvailable: "exclamationmark.circle.fill"
    }
  }
  
  var symbolColor: Color {
    switch self {
    case .defaultState: Color.secondary
    case .latestVersion: Color.green
    case .checkingForUpdate: Color.yellow
    case .newVersionAvailable: Color.blue
    }
  }
  
  var mainButtonText: String {
    switch self {
    case .defaultState: "Check for Updates"
    case .latestVersion: "Check for Updates"
    case .checkingForUpdate: "Checking for Updates..."
    case .newVersionAvailable: "Download Now"
    }
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
  
  @State var updateViewState: UpdateViewState = .defaultState
  
  var body: some View {
    VStack {
      
      ToggleWithLabel(isToggled: .constant(true), header: "Automatically check for new updates", description: "Checks for new releases on GitHub", showAllDescriptions: true)
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
        Image(systemName: updateViewState.symbol)
          .foregroundStyle(updateViewState.symbolColor)
          .padding(.trailing, 2)
        VStack(alignment: .leading) {
          Text(updateViewState.statusText)
            .bold()
            .padding(.bottom, 1)
          Text("SwiftDiffusion \(AppInfo.versionAndBuild)")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
        }
      }
      
      Spacer()
      
      Button(updateViewState.mainButtonText) {
        if updateViewState == .newVersionAvailable {
          if let latestRelease = updateManager.latestRelease, let releaseUrl = latestRelease.releaseDownloadUrlString, let url = URL(string: releaseUrl) {
            NSWorkspace.shared.open(url)
          }
        } else {
          Task {
            await updateManager.checkForUpdatesIfNeeded(force: true)
          }
        }
      }
      .padding(.bottom, 10)
      .disabled(updateManager.isCheckingForUpdate)
      .onChange(of: updateManager.isCheckingForUpdate) {
        updateViewStateBasedOnManager()
      }
      .onChange(of: updateManager.currentBuildIsLatestVersion) {
        updateViewStateBasedOnManager()
      }
      
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
    .onAppear {
      updateViewStateBasedOnManager()
    }
    
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
  func updateViewStateBasedOnManager() {
    if updateManager.isCheckingForUpdate {
      updateViewState = .checkingForUpdate
    } else if let currentBuildIsLatestVersion = updateManager.currentBuildIsLatestVersion {
      if currentBuildIsLatestVersion == false {
        updateViewState = .newVersionAvailable
      } else {
        updateViewState = .latestVersion
      }
    } else {
      updateViewState = .defaultState
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
