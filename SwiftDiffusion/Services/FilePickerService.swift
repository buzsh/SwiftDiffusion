//
//  FilePickerService.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

extension Constants.FileTypes {
  static let shellExtension = "sh"
  static let shellScriptType = UTType(filenameExtension: shellExtension)
}

struct FilePickerService {
  /// Presents an open panel dialog allowing the user to select a shell script file.
  ///
  /// This function asynchronously displays a file picker dialog configured to allow the selection of files with the `.sh` extension only. It ensures that the user cannot choose directories or multiple files. If the user selects a file and confirms, the function returns the path to the selected file. If the user cancels the dialog or selects a file of an incorrect type, the function returns `nil`.
  ///
  /// - Returns: A `String` representing the path to the selected `.sh` file, or `nil` if no file is selected or the operation is cancelled.
  @MainActor
  static func browseForShellFile() async -> String? {
    return await withCheckedContinuation { continuation in
      let panel = NSOpenPanel()
      panel.allowsMultipleSelection = false
      panel.canChooseDirectories = false
      
      if let shellScriptType = Constants.FileTypes.shellScriptType {
        panel.allowedContentTypes = [shellScriptType]
      } else {
        Debug.log("Failed to find UTType for .\(Constants.FileTypes.shellExtension) files")
        continuation.resume(returning: nil)
        return
      }
      
      panel.begin { response in
        if response == .OK, let url = panel.urls.first {
          if url.pathExtension == Constants.FileTypes.shellExtension {
            continuation.resume(returning: url.path)
          } else {
            Debug.log("Error: Selected file is not a .\(Constants.FileTypes.shellExtension) shell script file.\n > \(url)")
            continuation.resume(returning: nil)
          }
        }
      }
    }
  }
  /// Presents an open panel dialog allowing the user to select a directory.
  ///
  /// This function asynchronously displays a file picker dialog configured to allow the selection of directories only. It ensures that the user cannot choose files or multiple directories. If the user selects a directory and confirms, the function returns the path to the selected directory. If the user cancels the dialog or selects an incorrect type, the function returns `nil`.
  ///
  /// - Returns: A `String` representing the path to the selected directory, or `nil` if no directory is selected or the operation is cancelled.
  @MainActor
  static func browseForDirectory() async -> String? {
    return await withCheckedContinuation { continuation in
      let panel = NSOpenPanel()
      panel.allowsMultipleSelection = false
      panel.canChooseDirectories = true
      panel.canChooseFiles = false
      
      panel.begin { response in
        if response == .OK, let url = panel.urls.first {
          continuation.resume(returning: url.path)
        } else {
          continuation.resume(returning: nil)
        }
      }
    }
  }
}
