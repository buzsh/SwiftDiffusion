//
//  PromptView+ParseCivitai.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI

extension PromptView {
  
  func logAllVariables() {
    var debugOutput = ""
    
    debugOutput += "selectedModel: \(prompt.selectedModel?.name ?? "nil")\n"
    debugOutput += "samplingMethod: \(prompt.samplingMethod ?? "nil")\n"
    debugOutput += "positivePrompt: \(prompt.positivePrompt)\n"
    debugOutput += "negativePrompt: \(prompt.negativePrompt)\n"
    debugOutput += "width: \(prompt.width)\n"
    debugOutput += "height: \(prompt.height)\n"
    debugOutput += "cfgScale: \(prompt.cfgScale)\n"
    debugOutput += "samplingSteps: \(prompt.samplingSteps)\n"
    debugOutput += "seed: \(prompt.seed)\n"
    debugOutput += "batchCount: \(prompt.batchCount)\n"
    debugOutput += "batchSize: \(prompt.batchSize)\n"
    debugOutput += "clipSkip: \(prompt.clipSkip)\n"
    
    Debug.log(debugOutput)
  }
  
  func checkPasteboardAndUpdateFlag() {
    if let pasteboardContent = getPasteboardString() {
      if userHasGenerationDataInPasteboard(from: pasteboardContent) {
        generationDataInPasteboard = true
      } else {
        generationDataInPasteboard = false
      }
    }
  }
  
  func getPasteboardString() -> String? {
    return NSPasteboard.general.string(forType: .string)
  }
  
  func normalizeModelName(_ name: String) -> String {
    let lowercased = name.lowercased()
    let alphanumeric = lowercased.filter { $0.isLetter || $0.isNumber }
    return alphanumeric
  }
  
  func splitAndFilterModelName(_ name: String) -> [String] {
    let separators = CharacterSet(charactersIn: "_-.") // Add any other separators you expect
    let lowercased = name.lowercased()
    let splitNames = lowercased.components(separatedBy: separators)
    // Substrings to ignore
    let ignoreList = ["turbo", "safetensors", "v2", "dpmppsde"]
    // Filter out the ignored substrings
    return splitNames.filter { !ignoreList.contains($0) }
  }
  
  @MainActor
  func checkPasteboardAndUpdateFlag() async {
    // Assuming getPasteboardString() can be called directly without needing to be async
    // Consider making it async if it performs any lengthy operations
    if let pasteboardContent = getPasteboardString() {
      let hasData = userHasGenerationDataInPasteboard(from: pasteboardContent)
      // Update the state property directly, since we are on the main thread
      generationDataInPasteboard = hasData
    }
  }
  
  func userHasGenerationDataInPasteboard(from pasteboardContent: String) -> Bool {
    var relevantKeywordCounter = 0
    let keywords = ["Negative prompt:", "Steps:", "Seed:", "Sampler:", "CFG scale:", "Clip skip:", "Model:"]
    
    for keyword in keywords {
      if pasteboardContent.contains(keyword) {
        relevantKeywordCounter += 1
      }
      
      if relevantKeywordCounter >= 2 {
        return true
      }
    }
    return false
  }
  
  func parseAndSetPromptData(from pasteboardContent: String) {
    let lines = pasteboardContent.split(separator: "\n", omittingEmptySubsequences: true)
    
    // Set the positive prompt from the first line
    if let positivePromptLine = lines.first {
      prompt.positivePrompt = String(positivePromptLine)
    }
    
    // Loop through each line of the pasteboard content
    for line in lines {
      if line.contains("Model hash:") {
        parseModelHash(from: String(line))
      }
      if line.starts(with: "Negative prompt:") {
        let negativePrompt = line.replacingOccurrences(of: "Negative prompt: ", with: "")
        prompt.negativePrompt = negativePrompt
      } else {
        let parameters = line.split(separator: ",").map(String.init)
        if let modelParameter = parameters.first(where: { $0.trimmingCharacters(in: .whitespaces).starts(with: "Model:") }) {
          processModelParameter(modelParameter)
        }
        for parameter in parameters where !parameter.trimmingCharacters(in: .whitespaces).starts(with: "Model:") {
          processParameter(parameter)
        }
      }
    }
  }
  
  func parseModelHash(from line: String) {
    // This regex looks for "Model hash:" followed by any combination of text until it encounters another key
    // which is indicated by ", {Word}:" pattern. It captures the content right after "Model hash:".
    let regexPattern = "Model hash: ([^,]+(?:, [^,]+(?= Version:))*)"
    let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
    let nsLine = line as NSString
    let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
    
    guard let match = matches.first else {
      Debug.log("No model hash found in the line.")
      return
    }
    
    // Extracting the model hash values from the capture group
    let modelHashesString = nsLine.substring(with: match.range(at: 1))
    let modelHashes = modelHashesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    
    // Logging and processing each model hash value
    for modelHash in modelHashes {
      Debug.log("Processing model hash: \(modelHash)")
      processModelParameter("Model hash: \(modelHash)")
    }
  }
  
  func processModelParameter(_ parameter: String) {
    let keyValue = parameter.split(separator: ":", maxSplits: 1).map(String.init)
    guard keyValue.count == 2 else { return }
    let value = keyValue[1].trimmingCharacters(in: .whitespaces)
    
    Debug.log(value)
    let parsedModelName = value
    let parsedModelSubstrings = splitAndFilterModelName(parsedModelName)
    
    // Debug: Print parsed model substrings
    Debug.log("Parsed model substrings: \(parsedModelSubstrings)")
    
    // Find a matching model
    if let matchingModel = modelManager.items.first(where: { item in
      let itemSubstrings = splitAndFilterModelName(item.name)
      // Debug: Print item substrings
      Debug.log("Model item substrings: \(itemSubstrings) for model: \(item.name)")
      
      // Check if any substring matches
      let isMatch = parsedModelSubstrings.contains(where: itemSubstrings.contains)
      Debug.log("Attempting to match \(parsedModelSubstrings) with \(itemSubstrings): \(isMatch)")
      return isMatch
    }) {
      prompt.selectedModel = matchingModel
      Debug.log("Match found: \(matchingModel.name)")
    } else {
      Debug.log("No matching model found for \(parsedModelSubstrings)")
    }
  }
  
  // Helper function to process all other parameters
  func processParameter(_ parameter: String) {
    let keyValue = parameter.split(separator: ":", maxSplits: 1).map(String.init)
    guard keyValue.count == 2 else { return }
    let key = keyValue[0].trimmingCharacters(in: .whitespaces)
    let value = keyValue[1].trimmingCharacters(in: .whitespaces)
    
    switch key {
    case "Steps":
      Debug.log("Steps: \(value)")
      if let stepsValue = Double(value) {
        prompt.samplingSteps = stepsValue
      }
    case "Size":
      let sizeComponents = value.split(separator: "x").map(String.init)
      if sizeComponents.count == 2, let width = Double(sizeComponents[0]), let height = Double(sizeComponents[1]) {
        prompt.width = width
        prompt.height = height
      }
    case "Seed":
      prompt.seed = value
    case "Sampler":
      prompt.samplingMethod = value
    case "CFG scale":
      if let cfgScaleValue = Double(value) {
        prompt.cfgScale = cfgScaleValue
      }
    case "Clip skip":
      if let clipSkipValue = Double(value) {
        prompt.clipSkip = clipSkipValue
      }
      
    default:
      break
    }
  }
  
}

