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
    // dont automatically check pasteboard if disabled via userSettings
    if userSettings.disablePasteboardParsingForGenerationData { return }
    // check for pasteboard data
    if let pasteboardContent = getPasteboardString() {
      generationDataInPasteboard = userHasGenerationDataInPasteboard(from: pasteboardContent)
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
  /// Splits a model name into substrings based on specified separators and filters out any substrings that are in the ignore list or match the pattern "v" followed by any number of digits.
  func splitAndFilterModelName(_ name: String) -> [String] {
    let separators = CharacterSet(charactersIn: Constants.Parsing.separateModelKeywordsForParsingByCharacters)
    let lowercased = name.lowercased()
    let splitNames = lowercased.components(separatedBy: separators)
    let ignoreList = Constants.Parsing.ignoreModelKeywords
    let regexPattern = "^v\\d+$|^[0-9]+$"  // ignores "v2", "v3", "v10", etc., and also strings of just numbers like "123"
    let regex = try? NSRegularExpression(pattern: regexPattern)
    
    return splitNames.filter { splitName in
      if ignoreList.contains(splitName) {
        return false
      }
      
      // check if splitName matches the "v{numbers}" pattern
      if let regex = regex {
        let range = NSRange(location: 0, length: splitName.utf16.count)
        if regex.firstMatch(in: splitName, options: [], range: range) != nil {
          return false
        }
      }
      
      return true
    }
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
    parseLog(lines)
    currentPrompt.positivePrompt = buildPositivePrompt(from: lines)
    parseLog("positivePrompt: \(currentPrompt.positivePrompt)")
    // Loop through each line of the pasteboard content
    for line in lines {
      if line.contains("Model hash:") {
        parseModelHash(from: String(line))
      }
      if line.starts(with: "Negative prompt:") {
        let negativePrompt = line.replacingOccurrences(of: "Negative prompt: ", with: "")
        currentPrompt.negativePrompt = negativePrompt
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
  
  func buildPositivePrompt(from lines: [String.SubSequence]) -> String {
    var positivePrompt = ""
    for line in lines {
      if !line.contains("Negative prompt:") {
        positivePrompt = positivePrompt.appending(line)
      } else {
        return positivePrompt
      }
    }
    return positivePrompt
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
    if let matchingModel = modelManagerViewModel.items.first(where: { item in
      let itemSubstrings = splitAndFilterModelName(item.name)
      parseLog("Model item substrings: \(itemSubstrings) for model: \(item.name)")
      let isMatch = parsedModelSubstrings.contains(where: itemSubstrings.contains)
      parseLog("Attempting to match \(parsedModelSubstrings) with \(itemSubstrings): \(isMatch)")
      return isMatch
    }) {
      Debug.log("[processModelParameter] match: \(matchingModel.name)")
      currentPrompt.selectedModel = matchingModel
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
        currentPrompt.samplingSteps = stepsValue
      }
    case "Size":
      let sizeComponents = value.split(separator: "x").map(String.init)
      if sizeComponents.count == 2, let width = Double(sizeComponents[0]), let height = Double(sizeComponents[1]) {
        currentPrompt.width = width
        currentPrompt.height = height
      }
    case "Seed":
      currentPrompt.seed = value
    case "Sampler":
      currentPrompt.samplingMethod = value
    case "CFG scale":
      if let cfgScaleValue = Double(value) {
        currentPrompt.cfgScale = cfgScaleValue
      }
    case "Clip skip":
      if let clipSkipValue = Double(value) {
        currentPrompt.clipSkip = clipSkipValue
      }
      
    default:
      break
    }
  }
  
  /// Logs all current prompt variables to the debug console. This includes selected model, sampling method, prompts, dimensions, cfg scale, sampling steps, seed, batch count, batch size, and clip skip.
  func logAllVariables() {
    var debugOutput = ""
    debugOutput += "currentPrompt.\n"
    debugOutput += " selectedModel: \(currentPrompt.selectedModel?.name ?? "nil")\n"
    debugOutput += "samplingMethod: \(currentPrompt.samplingMethod ?? "nil")\n"
    debugOutput += "positivePrompt: \(currentPrompt.positivePrompt)\n"
    debugOutput += "negativePrompt: \(currentPrompt.negativePrompt)\n"
    debugOutput += "         width: \(currentPrompt.width)\n"
    debugOutput += "        height: \(currentPrompt.height)\n"
    debugOutput += "      cfgScale: \(currentPrompt.cfgScale)\n"
    debugOutput += " samplingSteps: \(currentPrompt.samplingSteps)\n"
    debugOutput += "          seed: \(currentPrompt.seed)\n"
    debugOutput += "    batchCount: \(currentPrompt.batchCount)\n"
    debugOutput += "     batchSize: \(currentPrompt.batchSize)\n"
    debugOutput += "      clipSkip: \(currentPrompt.clipSkip)\n"
    Debug.log(debugOutput)
  }
  
}

