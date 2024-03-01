//
//  FilterSortingSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import SwiftUI

struct FilterSortingSection: View {
  @Binding var sortingOrder: SidebarViewModel.SortingOrder
  @Binding var selectedModelName: String?
  @Binding var filterToolsButtonToggled: Bool
  let uniqueModelNames: [String]
  
  var body: some View {
    if filterToolsButtonToggled {
      VStack {
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
      }
      .frame(height: 110)
    }
  }
}
