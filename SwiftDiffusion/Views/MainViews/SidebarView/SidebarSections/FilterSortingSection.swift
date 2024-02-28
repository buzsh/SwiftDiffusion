//
//  FilterSortingSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import SwiftUI

struct FilterSortingSection: View {
  @Binding var sortingOrder: SidebarView.SortingOrder
  @Binding var selectedModelName: String?
  let uniqueModelNames: [String]
  
  var body: some View {
    List {
      Section(header: Text("Sorting")) {
        Menu(sortingOrder.rawValue) {
          Button("Most Recent") { sortingOrder = .mostRecent }
          Button("Least Recent") { sortingOrder = .leastRecent }
        }
      }
      
      Section(header: Text("Filters")) {
        Menu(selectedModelName ?? "Filter by Model") {
          Button("Show All") { selectedModelName = nil }
          Divider()
          ForEach(uniqueModelNames, id: \.self) { modelName in
            Button(modelName) { selectedModelName = modelName }
          }
        }
      }
    }
    .frame(height: 110)
  }
}
