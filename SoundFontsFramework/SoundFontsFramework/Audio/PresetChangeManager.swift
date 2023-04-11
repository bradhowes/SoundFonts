// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation
import os

/// Failure modes for a PresetChangeOperation
public enum PresetChangeFailure: Error, Equatable, CustomStringConvertible {
  /// No synth is available
  case noSynth
  /// Request was cancelled
  case cancelled
  /// Failed to load a preset
  case failedToLoad(error: NSError)

  /// The system error associated with a failure.
  var error: NSError? {
    switch self {
    case .noSynth: return nil
    case .cancelled: return nil
    case .failedToLoad(let err): return err
    }
  }

  public var description: String {
    switch self {
    case .noSynth: return "<PresetChangeFailure: no synth>"
    case .cancelled: return "<PresetChangeFailure: cancelled>"
    case .failedToLoad(error: let error): return "<PresetChangeFailure: failedToLoad - \(error.localizedDescription)>"
    }
  }
}

/**
 Controls changes to the active sound font preset of a synth. Requests are sent to a queue so that changes take place
 in an asynchronous but serial manner.
 */
final class PresetChangeManager {
  private lazy var log = Logging.logger("PresetChangeManager")
  private let queue = OperationQueue()
  private var active = true

  typealias OperationResult = Result<Preset, PresetChangeFailure>
  typealias AfterLoadBlock = (OperationResult) -> Void

  /**
   Create new manager.
   */
  init() {
    queue.maxConcurrentOperationCount = 1
    queue.underlyingQueue = DispatchQueue.global(qos: .userInitiated)
  }

  /**
   Place into the queue an operation to change the active preset. NOTE: this cancels any pending changes.

   - parameter synth: the synth to change
   - parameter url: the URL of the soundfont to use
   - parameter preset: the preset to change to
   - parameter afterLoadBlock: block to invoke after the change is done
   */
  func change(synth: PresetLoader, url: URL, preset: Preset, afterLoadBlock: AfterLoadBlock? = nil) {
    os_log(.debug, log: log, "change - %{public}s %{public}s", url.lastPathComponent, preset.description)
    guard active else { return }
    queue.cancelAllOperations()
    queue.addOperation(PresetChangeOperation(synth: synth, url: url, preset: preset, afterLoadBlock: afterLoadBlock))
  }

  /// Start accepting preset change requests.
  func start() {
    os_log(.debug, log: log, "start")
    active = true
  }

  /// Stop processing preset change requests.
  func stop() {
    os_log(.debug, log: log, "stop")
    active = false
    queue.cancelAllOperations()
    queue.waitUntilAllOperationsAreFinished()
  }
}

private final class PresetChangeOperation: Operation {
  private lazy var log = Logging.logger("PresetChangeOperation")

  private weak var synth: PresetLoader?
  private let url: URL
  private let preset: Preset

  private let afterLoadBlock: PresetChangeManager.AfterLoadBlock?
  private var operationResult: PresetChangeManager.OperationResult?

  override var isAsynchronous: Bool { true }

  init(synth: PresetLoader, url: URL, preset: Preset, afterLoadBlock: PresetChangeManager.AfterLoadBlock? = nil) {
    self.synth = synth
    self.url = url
    self.preset = preset
    self.afterLoadBlock = afterLoadBlock
    super.init()

    self.completionBlock = {
      if self.isCancelled {
        afterLoadBlock?(.failure(.cancelled))
      } else if let operationResult = self.operationResult {
        afterLoadBlock?(operationResult)
      }
    }

    os_log(.debug, log: log, "init")
  }

  override func main() {
    os_log(.debug, log: log, "main - BEGIN")

    guard let synth = self.synth else {
      os_log(.debug, log: log, "nil synth")
      operationResult = .failure(.noSynth)
      return
    }

    if self.isCancelled {
      operationResult = .failure(.cancelled)
      return
    }

    os_log(.debug, log: log, "before loadAndActivate")
    let result = synth.loadAndActivatePreset(preset, from: url)
    os_log(.debug, log: log, "after loadAndActivate - %d", result ?? noErr)

    os_log(.debug, log: log, "before afterLoadBlock")
    if let error = result {
      operationResult = .failure(.failedToLoad(error: error))
    } else {
      operationResult = .success(self.preset)
    }

    os_log(.debug, log: log, "after afterLoadBlock")
    os_log(.debug, log: log, "main - END")
  }
}
