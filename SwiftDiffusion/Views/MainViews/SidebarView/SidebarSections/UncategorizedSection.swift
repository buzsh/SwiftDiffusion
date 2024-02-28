//
//  UncategorizedSection.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/27/24.
//

import SwiftUI

struct UncategorizedSection: View {
  var sortedAndFilteredItems: [SidebarItem]
  @Binding var selectedItemID: UUID?
  @Binding var smallPreviewsButtonToggled: Bool
  @Binding var largePreviewsButtonToggled: Bool
  @Binding var modelNameButtonToggled: Bool
  
  var body: some View {
    if sortedAndFilteredItems.isEmpty {
      VStack(alignment: .center) {
        Spacer(minLength: 100)
        HStack(alignment: .center) {
          Spacer()
          VStack {
            Text("Saved prompts")
            Text("will appear here!")
          }
          Spacer()
        }
        Spacer()
      }
      .foregroundStyle(Color.secondary)
    } else {
      Section(header: Text("Uncategorized")) {
        ForEach(sortedAndFilteredItems) { item in
          SidebarStoredItemView(
            item: item,
            smallPreviewsButtonToggled: smallPreviewsButtonToggled,
            largePreviewsButtonToggled: largePreviewsButtonToggled,
            modelNameButtonToggled: modelNameButtonToggled
          )
          .padding(.vertical, 2)
          .contentShape(Rectangle())
          .onTapGesture {
            selectedItemID = item.id
          }
        }
      }
    }
  }
}
