//
//  ParseCivitai.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/7/24.
//

import Foundation
import AppKit

extension Constants.Debug {
  static let enableParseLog = false
}

extension Constants.Parsing {
  static let ignoreModelKeywords = ["turbo", "safetensors", "dpmppsde"]
  static let separateModelKeywordsForParsingByCharacters = "_-."
}

class ParseCivitai {
  private var checkpoints: [CheckpointModel] = []
  private var vaeModels: [VaeModel] = []
  
  init(checkpoints: [CheckpointModel], vaeModels: [VaeModel]) {
    self.checkpoints = checkpoints
    self.vaeModels = vaeModels
  }
  
  let mapModelData = MapModelData()
  
  /// Enable Debug.log console output if `Constants.Debug.enableParseLog` is `true`
  private func parseLog<T>(_ value: T) {
    if Constants.Debug.enableParseLog {
      Debug.log(value)
    }
  }
  
  func parsePastablePromptModel(_ pasteboard: String) -> StoredPromptModel {
    let prompt = StoredPromptModel()
    let lines = pasteboard.split(separator: "\n", omittingEmptySubsequences: true)
    prompt.positivePrompt = buildPositivePrompt(from: lines)
    
    var matchedCheckpointModel: CheckpointModel?
    for line in lines {
      if line.contains("Model hash:") {
        matchedCheckpointModel = parseModelHash(from: String(line))
      }
      
      if line.starts(with: "Negative prompt:") {
        let negativePrompt = line.replacingOccurrences(of: "Negative prompt: ", with: "")
        prompt.negativePrompt = negativePrompt
      } else {
        let parameters = line.split(separator: ",").map(String.init)
        if matchedCheckpointModel == nil {
          if let modelParameter = parameters.first(where: { $0.trimmingCharacters(in: .whitespaces).starts(with: "Model:") }) {
            matchedCheckpointModel = processModelParameter(modelParameter)
          }
        }
        // Continue parsing for other parameters (excluding those starting with Model)
        for parameter in parameters where !parameter.trimmingCharacters(in: .whitespaces).starts(with: "Model:") {
          processParameter(parameter, currentPrompt: prompt)
        }
      }
    }
    
    if let checkpointModelToSelect = matchedCheckpointModel {
      prompt.selectedModel = mapModelData.toStoredCheckpoint(from: checkpointModelToSelect)
    }
    return prompt
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
  
  
  // MARK: Deprecated
  /// Parses the pasteboard content to extract prompt data, including positive and negative prompts, and other parameters like model hash.
  func parseAndSetPromptData(from pasteboardContent: String, currentPrompt: StoredPromptModel) {
    let lines = pasteboardContent.split(separator: "\n", omittingEmptySubsequences: true)
    parseLog(lines)
    
    currentPrompt.positivePrompt = buildPositivePrompt(from: lines)
    parseLog("positivePrompt: \(currentPrompt.positivePrompt)")
    
    var matchedCheckpointModel: CheckpointModel?
    for line in lines {
      if line.contains("Model hash:") {
        matchedCheckpointModel = parseModelHash(from: String(line))
      }
      
      if line.starts(with: "Negative prompt:") {
        let negativePrompt = line.replacingOccurrences(of: "Negative prompt: ", with: "")
        currentPrompt.negativePrompt = negativePrompt
      } else {
        let parameters = line.split(separator: ",").map(String.init)
        // Continue parsing for model
        if matchedCheckpointModel == nil {
          if let modelParameter = parameters.first(where: { $0.trimmingCharacters(in: .whitespaces).starts(with: "Model:") }) {
            matchedCheckpointModel = processModelParameter(modelParameter)
          }
        }
        // Continue parsing for other parameters (excluding those starting with Model)
        for parameter in parameters where !parameter.trimmingCharacters(in: .whitespaces).starts(with: "Model:") {
          processParameter(parameter, currentPrompt: currentPrompt)
        }
      }
    }
    
    if let checkpointModelToSelect = matchedCheckpointModel {
      Task {
        currentPrompt.selectedModel = await mapModelData.toStoredCheckpointModel(from: checkpointModelToSelect)
      }
    }
    
  }
  
  /// Constructs a positive prompt string from an array of lines, excluding lines that contain specific keywords.
  ///
  /// This function iterates over each line of input and appends it to the resulting positive prompt string unless the line contains any of the predefined keywords indicating that it pertains to parameters not related to the positive prompt itself. The predefined keywords include "Negative prompt:", "Steps:", "VAE:", "Size:", "Seed:", "Model:", "Sampler:", "CFG scale:", "Clip skip:". The construction of the positive prompt stops and returns immediately when any of these keywords are encountered in a line, even if it's partway through the input lines.
  ///
  /// - Parameter lines: An array of `String.SubSequence` representing the lines of text to be processed into a positive prompt.
  /// - Returns: A `String` containing the constructed positive prompt, which may be empty if no applicable lines are found or if an excluded keyword is encountered in the first line.
  func buildPositivePrompt(from lines: [String.SubSequence]) -> String {
    let excludedSubstrings = ["Negative prompt:", "Steps:", "VAE:", "Size:", "Seed:", "Model:", "Sampler:", "CFG scale:", "Clip skip:"]
    
    var positivePrompt = ""
    for line in lines {
      if !excludedSubstrings.contains(where: line.contains) {
        positivePrompt += String(line) + "\n"
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
  func parseModelHash(from line: String) -> CheckpointModel? {
    let regexPattern = "Model hash: ([^,]+(?:, [^,]+(?= Version:))*)"
    let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
    let nsLine = line as NSString
    let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsLine.length))
    
    guard let match = matches.first else {
      parseLog("No model hash found in the line.")
      return nil
    }
    
    let modelHashesString = nsLine.substring(with: match.range(at: 1))
    let modelHashes = modelHashesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    for modelHash in modelHashes {
      Debug.log("modelHash: \(modelHash)")
      
      for checkpoint in checkpoints {
        if let apiHash = checkpoint.checkpointApiModel?.modelHash,
           modelHash == apiHash {
          
          return checkpoint //mapModelData.toStoredCheckpointModel(from: checkpoint)
        }
      }
      
      return processModelParameter("Model hash: \(modelHash)")
    }
    return nil
  }
  /// Processes a model parameter by extracting the value from a key-value pair and attempting to match it with a model in the model manager.
  func processModelParameter(_ parameter: String) -> CheckpointModel? {
    let keyValue = parameter.split(separator: ":", maxSplits: 1).map(String.init)
    guard keyValue.count == 2 else { return nil }
    let value = keyValue[1].trimmingCharacters(in: .whitespaces)
    
    parseLog(value)
    let parsedModelName = value
    let parsedModelSubstrings = splitAndFilterModelName(parsedModelName)
    parseLog("Parsed model substrings: \(parsedModelSubstrings)")
    
    for checkpoint in checkpoints {
      let itemSubstrings = splitAndFilterModelName(checkpoint.name)
      parseLog("Model item substrings: \(itemSubstrings) for model: \(checkpoint.name)")
      if parsedModelSubstrings.contains(where: itemSubstrings.contains) {
        parseLog("Match \(parsedModelSubstrings) with \(itemSubstrings)")
        return checkpoint
      }
    }
    
    parseLog("No matching model found for \(parsedModelSubstrings)")
    let allTitles = checkpoints.compactMap { $0.checkpointApiModel?.title }.joined(separator: ", ")
    Debug.log("[processModelParameter] Could not find match for \(value).\n > substrings parsed: \(parsedModelSubstrings)\n > \(allTitles)")
    return nil
  }
  
  // Helper function to process all other parameters
  func processParameter(_ parameter: String, currentPrompt: StoredPromptModel) {
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
    case "Width":
      if let width = Double(value) {
        currentPrompt.width = width
      }
    case "Height":
      if let height = Double(value) {
        currentPrompt.height = height
      }
    case "Seed":
      currentPrompt.seed = value
    case "Sampler":
      currentPrompt.samplingMethod = updateSamplingMethod(with: value)
    case "CFG scale":
      if let cfgScaleValue = Double(value) {
        currentPrompt.cfgScale = cfgScaleValue
      }
    case "Clip skip":
      if let clipSkipValue = Double(value) {
        currentPrompt.clipSkip = clipSkipValue
      }
    case "Batch count":
      if let batchCount = Double(value) {
        currentPrompt.batchCount = batchCount
      }
    case "Batch size":
      if let batchSize = Double(value) {
        currentPrompt.batchSize = batchSize
      }
    case "VAE":
      Task {
        currentPrompt.vaeModel = await mapModelData.toStoredVaeModel(from: updateVaeModel(with: value))
      }
    default:
      break
    }
  }
  
  /// Logs all current prompt variables to the debug console. This includes selected model, sampling method, prompts, dimensions, cfg scale, sampling steps, seed, batch count, batch size, and clip skip.
  func logAllVariables(currentPrompt: StoredPromptModel) {
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


extension ParseCivitai {
  func updateSamplingMethod(with name: String) -> String? {
    if Constants.coreMLSamplingMethods.contains(name) || Constants.pythonSamplingMethods.contains(name) {
      return name
    } else {
      Debug.log("No sampling method found with the name \(name)")
      return nil
    }
  }
  
  func updateVaeModel(with name: String) -> VaeModel? {
    if let matchingModel = vaeModels.first(where: { $0.name == name }) {
      return matchingModel
    } else {
      Debug.log("No VAE Model found with the name \(name)")
      return nil
    }
  }
}
