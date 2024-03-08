//
//  SeedRows.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI
import CompactSlider

#Preview {
  CommonPreviews.promptView
}

struct SeedRow: View {
  enum ControlButtonLayout { case above, beside }
  @Binding var seed: String
  var controlButtonLayout: ControlButtonLayout = .above
  
  var body: some View {
    
    VStack(alignment: .leading) {
      HStack {
        PromptRowHeading(title: "Seed")
          .padding(.leading, 8)
        Spacer()
        if controlButtonLayout == .above {
          SeedControlButtonLayout(seed: $seed)
        }
      }
      HStack {
        TextField("", text: $seed)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(.body, design: .monospaced))
        
        if controlButtonLayout == .beside {
          SeedControlButtonLayout(seed: $seed)
        }
      }
    }
    
    .padding(.bottom, Constants.Layout.promptRowPadding)
  }
}

struct SeedControlButtonLayout: View {
  @Binding var seed: String
  
  var body: some View {
    SymbolButton(symbol: .shuffle, action: {
      seed = "-1"
    })
    SymbolButton(symbol: .repeatLast, action: {
      Debug.log("Repeat last seed")
    })
    .disabled(true)
  }
}

struct SeedAndClipSkipRow: View {
  @Binding var seed: String
  @Binding var clipSkip: Double
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        VStack(alignment: .leading) {
          HStack {
            PromptRowHeading(title: "Seed")
              .padding(.leading, 8)
            Spacer()
            SeedControlButtonLayout(seed: $seed)
          }
          TextField("", text: $seed)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.system(.body, design: .monospaced))
        }
        
        VStack {
          CompactSlider(value: $clipSkip, in: 1...12, step: 1) {
            Text("Clip Skip")
            Spacer()
            Text("\(Int(clipSkip))")
          }
        }
        .padding(.top, 18)
      }
    }
    .padding(.bottom, Constants.Layout.promptRowPadding)
  }
}

struct SeedRowAndClipSkipHalfRow: View {
  @Binding var seed: String
  @Binding var clipSkip: Double
  
  var body: some View {
    VStack {
      HStack {
        HalfMaxWidthView {}
        CompactSlider(value: $clipSkip, in: 1...12, step: 1) {
          Text("Clip Skip")
          Spacer()
          Text("\(Int(clipSkip))")
        }
      }
    }
    VStack(alignment: .leading) {
      HStack {
        PromptRowHeading(title: "Seed")
          .padding(.leading, 8)
        Spacer()
        SeedControlButtonLayout(seed: $seed)
      }
      TextField("", text: $seed)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .font(.system(.body, design: .monospaced))
    }
    .padding(.top, 6)
    .padding(.bottom, 6)
  }
}

struct ExportSelectionRow: View {
  @Binding var batchCount: Double
  @Binding var batchSize: Double
  
  var body: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Export Amount")
      HStack {
        CompactSlider(value: $batchCount, in: 1...100, step: 1) {
          Text("Batch Count")
          Spacer()
          Text("\(Int(batchCount))")
        }
        .disabled(true)
        
        CompactSlider(value: $batchSize, in: 1...8, step: 1) {
          Text("Batch Size")
          Spacer()
          Text("\(Int(batchSize))")
        }
      }
    }
    .padding(.bottom, Constants.Layout.promptRowPadding)
  }
}
