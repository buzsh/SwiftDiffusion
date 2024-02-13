//
//  SettingsView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

extension Constants.WindowSize {
  struct Settings {
    static let defaultWidth: CGFloat = 670
    static let defaultHeight: CGFloat = 700
  }
}

struct SettingsView: View {
  @ObservedObject var userSettings = UserSettings.shared
  @EnvironmentObject var modelManagerViewModel: ModelManagerViewModel
  
  @Environment(\.presentationMode) var presentationMode
  
  @State var selectedTab: SettingsTab = SettingsTab(rawValue: UserDefaults.standard.string(forKey: "selectedSettingsTab") ?? "") ?? .engine
  
  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        
        SettingsSectionHeader(userSettings: userSettings, selectedTab: selectedTab)
        
        VStack(alignment: .leading) {
          switch selectedTab {
          case .general:
            GeneralSection(userSettings: userSettings)
          case .files:
            FilesSection(userSettings: userSettings)
          case .prompt:
            PromptSection(userSettings: userSettings)
          case .engine:
            EngineSection(userSettings: userSettings)
          case .developer:
            DeveloperSection(userSettings: userSettings)
          }
        }
        .padding(.top).padding(.horizontal, 14)
        .onChange(of: userSettings.stableDiffusionModelsPath) {
          Task {
            await modelManagerViewModel.loadModels()
          }
        }
      }
      .frame(maxHeight: .infinity)
      
      VStack {
        HStack {
          Button("Restore Defaults") {
            userSettings.restoreDefaults()
          }
          Spacer()
          Button("Done") {
            presentationMode.wrappedValue.dismiss()
          }
        }
        .padding(10)
      }
      .background(Color(NSColor.windowBackgroundColor))
    }
    .frame(minWidth: 615, idealWidth: 600, minHeight: 300, idealHeight: 400)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        HStack {
          
          ForEach(SettingsTab.allCases, id: \.self) { tab in
            Button(action: {
              self.selectedTab = tab
            }) {
              VStack {
                Image(systemName: tab.symbol)
                  .padding(.bottom, 0.1)
                Text(tab.rawValue)
                  .font(.system(size: 10))
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
            .buttonStyle(ToolbarTabButtonStyle(isSelected: selectedTab == tab))
          }
          
        }
      }
    }
  }
}

#Preview {
  SettingsView()
    .frame(width: 600, height: 700)
}
