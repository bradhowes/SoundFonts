// Copyright © 2020 Brad Howes. All rights reserved.

import AVFoundation
import os

private final class PresetChangeOperation: Operation {
  private lazy var log = Logging.logger("PresetChangeOperation")

  private weak var sampler: AVAudioUnitSampler?
  private let url: URL
  private let program: UInt8
  private let bankMSB: UInt8
  private let bankLSB: UInt8
  private let afterLoadBlock: (() -> Void)?
  private var _finished = false
  private var _executing = false

  override var isFinished: Bool {
    get { _finished }
    set {
      willChangeValue(forKey: "isFinished")
      _finished = newValue
      didChangeValue(forKey: "isFinished")
    }
  }

  override var isExecuting: Bool {
    get { _executing }
    set {
      willChangeValue(forKey: "isExecuting")
      _executing = newValue
      didChangeValue(forKey: "isExecuting")
    }
  }

  override var isAsynchronous: Bool { true }

  init(sampler: AVAudioUnitSampler, url: URL, program: UInt8, bankMSB: UInt8, bankLSB: UInt8,
       afterLoadBlock: (() -> Void)? = nil) {
    self.sampler = sampler
    self.url = url
    self.program = program
    self.bankMSB = bankMSB
    self.bankLSB = bankLSB
    self.afterLoadBlock = afterLoadBlock
    super.init()
    os_log(.info, log: log, "init")
  }

  override func start() {
    os_log(.info, log: log, "start")

    isExecuting = true
    guard let sampler = self.sampler else {
      os_log(.info, log: log, "nil sampler")
      isFinished = true
      return
    }

    if self.isCancelled {
      os_log(.info, log: log, "op cancelled")
      isFinished = true
      return
    }

    do {
      os_log(.info, log: log, "before loadSoundBankInstrument")
      try sampler.loadSoundBankInstrument(at: url, program: program, bankMSB: bankMSB, bankLSB: bankLSB)
      os_log(.info, log: log, "after loadSoundBankInstrument")
    } catch let error as NSError {
      switch error.code {
      case -1: break
      case -43, -54: // permission error for SF2 file
        NotificationCenter.default.post(name: .soundFontFileAccessDenied, object: url.lastPathComponent)
      default:
        os_log(.error, log: log, "failed loadSoundBankInstrument - %d %{public}s", errno, error.localizedDescription)
      }
    }

    afterLoadBlock?()
    isExecuting = false
    isFinished = true
  }
}

final class PresetChangeManager {
  private lazy var log = Logging.logger("PresetChangeManager")
  private let queue = OperationQueue()
  private var active = true

  init() {
    queue.maxConcurrentOperationCount = 1
    queue.underlyingQueue = DispatchQueue.global(qos: .userInitiated)
  }

  func start() {
    os_log(.info, log: log, "start")
    active = true
  }

  func change(sampler: AVAudioUnitSampler, url: URL, program: UInt8, bankMSB: UInt8, bankLSB: UInt8,
              afterLoadBlock: (() -> Void)? = nil) {
    os_log(.info, log: log, "change - %{public}s %d %d %d", url.lastPathComponent, program, bankMSB, bankLSB)
    guard active else { return }
    queue.addOperation(PresetChangeOperation(sampler: sampler, url: url, program: program, bankMSB: bankMSB,
                                             bankLSB: bankLSB, afterLoadBlock: afterLoadBlock))
  }

  func stop() {
    os_log(.info, log: log, "stop")
    active = false
    queue.cancelAllOperations()
    queue.waitUntilAllOperationsAreFinished()
  }
}
