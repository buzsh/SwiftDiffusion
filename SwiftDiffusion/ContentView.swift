//
//  ContentView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI

extension Constants.Layout {
  static let verticalPadding: CGFloat = 8
}

enum ViewManager {
  case main, console
  
  var title: String {
    switch self {
    case .main: return "Home"
    case .console: return "Console"
    }
  }
}

extension ViewManager: Hashable, Identifiable {
  var id: Self { self }
}

struct ContentView: View {
  // Main
  @ObservedObject var mainViewModel: MainViewModel
  // Console
  @ObservedObject var scriptManager: ScriptManager
  @Binding var scriptPathInput: String
  // Views
  @State private var selectedView: ViewManager = .main
  
  var body: some View {
    NavigationView {
      // Sidebar
      List {
        NavigationLink(destination: MainView(prompt: mainViewModel)) {
          Label("Prompt", systemImage: "text.bubble")
        }
        NavigationLink(destination: ConsoleView(scriptManager: scriptManager, scriptPathInput: $scriptPathInput)) {
          Label("Console", systemImage: "terminal")
        }
      }
      .navigationSplitViewColumnWidth(min: 200, ideal: 350)
      .listStyle(SidebarListStyle())
      .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button(action: {
            Debug.log("Sidebar item selected")
          }) {
            Image(systemName: "gear")
          }
        }
      }
      
      // Default View
      switch selectedView {
      case .main:
        MainView(prompt: mainViewModel)
      case .console:
        ConsoleView(scriptManager: scriptManager, scriptPathInput: $scriptPathInput)
      }
    }
    .onAppear {
      scriptPathInput = scriptManager.scriptPath ?? ""
    }
    .navigationTitle(selectedView.title)
    .toolbar {
      ToolbarItemGroup(placement: .automatic) {
        Picker("Options", selection: $selectedView) {
          Text("Prompt").tag(ViewManager.main)
          Text("Console").tag(ViewManager.console)
        }
        .pickerStyle(SegmentedPickerStyle())
      }
      
      ToolbarItem(placement: .automatic) {
        Button(action: {
          Debug.log("Toolbar item selected")
        }) {
          Image(systemName: "gear")
        }
      }
    }
  }
  
}

/*
 #Preview {
  ContentView()
 }
 */
