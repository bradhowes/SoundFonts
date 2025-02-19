// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation
import os

/**
 Controls changes to the active sound font preset of a synth. Requests are sent to a queue so that changes take place
 in an asynchronous but serial manner.
 */
final class PresetChangeManager {
  private lazy var log: Logger = Logging.logger("PresetChangeManager")
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
    log.debug("change - \(url.lastPathComponent, privacy: .public) \(preset.description, privacy: .public)")
    guard active else { return }
    queue.cancelAllOperations()
    queue.addOperation(PresetChangeOperation(synth: synth, url: url, preset: preset, afterLoadBlock: afterLoadBlock))
  }

  /// Start accepting preset change requests.
  func start() {
    log.debug("start")
    active = true
  }

  /// Stop processing preset change requests.
  func stop() {
    log.debug("stop")
    active = false
    queue.cancelAllOperations()
    queue.waitUntilAllOperationsAreFinished()
  }
}

private final class PresetChangeOperation: Operation, @unchecked Sendable {
  private lazy var log: Logger = Logging.logger("PresetChangeOperation")

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

    log.debug("init")
  }

  override func main() {
    log.debug("main - BEGIN")

    guard let synth = self.synth else {
      log.debug("nil synth")
      operationResult = .failure(.noSynth)
      return
    }

    if self.isCancelled {
      operationResult = .failure(.cancelled)
      return
    }

    log.debug("before loadAndActivatePreset \(self.url.lastPathComponent, privacy: .public) \(self.preset.description, privacy: .public)")
    let secure = url.startAccessingSecurityScopedResource()
    let result = synth.loadAndActivatePreset(preset, from: url)
    log.debug("after loadAndActivate - \(result.debugDescription)")
    if secure { url.stopAccessingSecurityScopedResource() }
    log.debug("before afterLoadBlock")
    if let error = result {
      operationResult = .failure(.failedToLoad(error: error))
    } else {
      operationResult = .success(self.preset)
    }

    log.debug("after afterLoadBlock")
    log.debug("main - END")
  }
}

/// Failure modes for a PresetChangeOperation
enum PresetChangeFailure: Error, Equatable, CustomStringConvertible {
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

  var description: String {
    switch self {
    case .noSynth: return "<PresetChangeFailure: no synth>"
    case .cancelled: return "<PresetChangeFailure: cancelled>"
    case .failedToLoad(error: let error): return "<PresetChangeFailure: failedToLoad - \(error.localizedDescription)>"
    }
  }
}
