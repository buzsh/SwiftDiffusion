//
//  VaeModelMenu.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/25/24.
//

import SwiftUI

struct VaeModelMenu: View {
  @EnvironmentObject var sidebarModel: SidebarModel
  @EnvironmentObject var vaeModelsManager: ModelManager<VaeModel>
  @Binding var vaeModel: StoredVaeModel?
  
  @State private var isExpanded: Bool = false
  
  var body: some View {
    VStack {
      HStack {
        ExpandableSectionHeader(title: "VAE Model", isExpanded: $isExpanded)
        
        Spacer()
        
        if !isExpanded {
          Text(vaeModel?.name ?? "None")
            .foregroundStyle(.secondary)
            .opacity(0.8)
            .lineLimit(1)
            .truncationMode(.tail)
        }
      }
      
      if isExpanded {
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Menu {
              Button("None") {
                vaeModel = nil
              }
              Divider()
              
              ForEach(vaeModelsManager.models.sorted(by: { $0.name.lowercased() < $1.name.lowercased() }), id: \.id) { vae in
                Button(vae.name) {
                  let mapModelData = MapModelData()
                  vaeModel = mapModelData.toStoredVaeModel(from: vae)
                }
              }
            } label: {
              Label(vaeModel?.name ?? "None", systemImage: "line.3.crossed.swirl.circle")
            }
          }
        }
      }
      
    }
    .padding(.vertical, 10)
  }
}

#Preview {
  CommonPreviews.promptView
}
