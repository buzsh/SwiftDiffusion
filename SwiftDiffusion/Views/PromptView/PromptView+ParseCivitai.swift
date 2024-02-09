//
//  PromptView+ParseCivitai.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI

extension Constants.Debug {
  static let enableParseLog = false
}

extension Constants.Parsing {
  static let ignoreModelKeywords = ["turbo", "safetensors", "v2", "dpmppsde"]
  static let separateModelKeywordsForParsingByCharacters = "_-."
}

extension PromptView {
  /// Enable Debug.log console output if `Constants.Debug.enableParseLog` is `true`
  private func parseLog<T>(_ value: T) {
    if Constants.Debug.enableParseLog {
      Debug.log(value)
    }
  }
  
  /// Checks the system pasteboard for generation data. If found, updates a flag to indicate that generation data is present.
  func checkPasteboardAndUpdateFlag() {
    if let pasteboardContent = getPasteboardString() {
      if userHasGenerationDataInPasteboard(from: pasteboardContent) {
        generationDataInPasteboard = true
      } else {
        generationDataInPasteboard = false
      }
    }
  }
  /// Returns the string currently stored in the system's pasteboard, if available.
  func getPasteboardString() -> String? {
    return NSPasteboard.general.string(forType: .string)
  }
  /// Normalizes a model name by converting it to lowercase and removing all non-alphanumeric characters.
  func normalizeModelName(_ name: String) -> String {
    let lowercased = name.lowercased()
    let alphanumeric = lowercased.filter { $0.isLetter || $0.isNumber }
    return alphanumeric
  }
  /// Splits a model name into substrings based on specified separators and filters out any substrings that are in the ignore list.
  func splitAndFilterModelName(_ name: String) -> [String] {
    let separators = CharacterSet(charactersIn: Constants.Parsing.separateModelKeywordsForParsingByCharacters)
    let lowercased = name.lowercased()
    let splitNames = lowercased.components(separatedBy: separators)
    let ignoreList = Constants.Parsing.ignoreModelKeywords
    return splitNames.filter { !ignoreList.contains($0) }
  }
  /// Asynchronously checks the system pasteboard for generation data and updates a flag accordingly. Intended to be used on the main actor to ensure UI updates are handled correctly.
  @MainActor
  func checkPasteboardAndUpdateFlag() async {
    if let pasteboardContent = getPasteboardString() {
      let hasData = userHasGenerationDataInPasteboard(from: pasteboardContent)
      generationDataInPasteboard = hasData
    }
  }
  /// Determines if the pasteboard content contains generation data by looking for specific keywords.
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
  /// Parses the pasteboard content to extract prompt data, including positive and negative prompts, and other parameters like model hash.
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
  /// Parses the "Model hash:" value(s) from a given line of text, extracting and processing each hash found.
  ///
  /// This regex looks for `"Model hash:"` followed by any combination of text until it encounters another key, indicated by "{Word}:" pattern. ie.
  /// ```swift
  /// "Sampler: DPM++ SDE Karras, CFG scale: 2, Model hash: 4726d3bab1, dreamshaperXL_v2TurboDpmppSDE Version: ComfyUI"
  /// // to
  /// ["4726d3bab1", "dreamshaperXL_v2TurboDpmppSDE"]
  /// ```
  func parseModelHash(from line: String) {
    let regexPattern = "Model hash: ([^,]+(?:, [^,]+(?= Version:))*)"
    let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
    let nsLine = line as NSString
    let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
    
    guard let match = matches.first else {
      parseLog("No model hash found in the line.")
      return
    }
    let modelHashesString = nsLine.substring(with: match.range(at: 1))
    let modelHashes = modelHashesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    for modelHash in modelHashes {
      parseLog("Processing model hash: \(modelHash)")
      processModelParameter("Model hash: \(modelHash)")
    }
  }
  /// Processes a model parameter by extracting the value from a key-value pair and attempting to match it with a model in the model manager.
  func processModelParameter(_ parameter: String) {
    let keyValue = parameter.split(separator: ":", maxSplits: 1).map(String.init)
    guard keyValue.count == 2 else { return }
    let value = keyValue[1].trimmingCharacters(in: .whitespaces)
    
    parseLog(value)
    let parsedModelName = value
    let parsedModelSubstrings = splitAndFilterModelName(parsedModelName)
    parseLog("Parsed model substrings: \(parsedModelSubstrings)")
    if let matchingModel = modelManager.items.first(where: { item in
      let itemSubstrings = splitAndFilterModelName(item.name)
      parseLog("Model item substrings: \(itemSubstrings) for model: \(item.name)")
      let isMatch = parsedModelSubstrings.contains(where: itemSubstrings.contains)
      parseLog("Attempting to match \(parsedModelSubstrings) with \(itemSubstrings): \(isMatch)")
      return isMatch
    }) {
      prompt.selectedModel = matchingModel
      parseLog("Match found: \(matchingModel.name)")
    } else {
      parseLog("No matching model found for \(parsedModelSubstrings)")
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
      parseLog("Steps: \(value)")
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
  
  /// Logs all current prompt variables to the debug console. This includes selected model, sampling method, prompts, dimensions, cfg scale, sampling steps, seed, batch count, batch size, and clip skip.
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
  
}

