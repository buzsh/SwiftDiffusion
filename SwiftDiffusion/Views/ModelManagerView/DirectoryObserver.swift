//
//  DirectoryObserver.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import Foundation

class DirectoryObserver {
  private var fileDescriptor: Int32 = -1
  private var source: DispatchSourceFileSystemObject?
  private var observationTask: Task<(), Never>?
  
  func startObserving(url: URL, onChange: @escaping () async -> Void) {
    stopObserving() // Ensure not already observing
    
    fileDescriptor = open(url.path, O_EVTONLY)
    guard fileDescriptor != -1 else {
      Debug.log("Unable to open the directory.")
      return
    }
    
    let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: .global())
    self.source = source
    
    observationTask = Task {
      source.setEventHandler { [weak self] in
        guard self != nil else { return }
        Task { await onChange() }
      }
      
      source.setCancelHandler { [weak self] in
        guard let self = self else { return }
        close(self.fileDescriptor)
        self.fileDescriptor = -1
      }
      
      source.resume()
    }
  }
  
  func stopObserving() {
    source?.cancel()
    observationTask?.cancel()
    observationTask = nil
    source = nil
  }
  
  deinit {
    stopObserving()
  }
}
