// Copyright © 2021 Brad Howes. All rights reserved.

import Foundation
import UIKit
import os.log

class ConsolidatedConfigFileMonitor: NSObject {
  private let log = Logging.logger("ConsolidatedConfigFileMonitor")

  private weak var configFile: ConsolidatedConfigFile!
  private var stateObserver: Any?
  private var documentState: UIDocument.State { configFile.documentState }
  private var transferring: Bool = false
  private var wasDisabled: Bool = false

  init(configFile: ConsolidatedConfigFile) {
    self.configFile = configFile
    super.init()

    stateObserver = NotificationCenter.default.addObserver(self, selector: #selector(processStateChange(_:)),
                                                           name: UIDocument.stateChangedNotification,
                                                           object: configFile)
    NotificationCenter.default.addObserver(self, selector: #selector(closeFile(_:)),
                                           name: UIApplication.willResignActiveNotification,
                                           object: configFile)

    NotificationCenter.default.addObserver(self, selector: #selector(openFile(_:)),
                                           name: UIApplication.willEnterForegroundNotification,
                                           object: configFile)
  }

  deinit {
    if let stateObserver = self.stateObserver {
      NotificationCenter.default.removeObserver(stateObserver)
    }
  }

  @objc func closeFile(_ notification: Notification) {
    os_log(.info, log: log, "closeFile BEGIN")
    configFile.close { ok in
      os_log(.info, log: self.log, "closeFile - %d", ok)
    }
    os_log(.info, log: log, "closeFile END")
  }

  @objc func openFile(_ notification: Notification) {
    os_log(.info, log: log, "openFile BEGIN")
    configFile.restore()
    os_log(.info, log: log, "openFile END")
  }

  @objc func processStateChange(_ notification: Notification) {
    os_log(.info, log: log, "processStateChange: %d", documentState.rawValue)

    let documentState = configFile.documentState

    if documentState == .normal { os_log(.info, log: log, "processStateChange - entered normal state") }

    if documentState.contains(.closed) { os_log(.info, log: log, "processStateChange - closed") }

    if documentState.contains(.editingDisabled) {
      os_log(.info, log: log, "processStateChange - editing disabled")
      wasDisabled = true
    } else if wasDisabled {
      os_log(.info, log: log, "processStateChange - editing enabled")
      wasDisabled = false
      configFile.restore()
    }

    if documentState.contains(.inConflict) {
      os_log(.info, log: log, "processStateChange - conflict was detected")
      resolveDocumentConflict()
    }

    if documentState.contains(.savingError) {
      os_log(.info, log: log, "processStateChange - failed to save document")
      configFile.restore()
    }

    handleDocStateForTransfers()
  }

  private func handleDocStateForTransfers() {
    if transferring {
      if !documentState.contains(.progressAvailable) {
        os_log(.info, log: log, "handleDocStateForTransfers - transfer is done")
        transferring = false
      }
    } else if documentState.contains(.progressAvailable) {
      os_log(.info, log: log, "handleDocStateForTransfers - transfer is in progress")
      transferring = true
    }
  }

  private func resolveDocumentConflict() {

    // To accept the current version, remove the other versions,
    // and resolve all the unresolved versions.
    do {
      try NSFileVersion.removeOtherVersionsOfItem(at: configFile.fileURL)

      if let conflictingVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: configFile.fileURL) {
        for version in conflictingVersions {
          version.isResolved = true
        }
      }
    } catch let error {
      os_log(.error, log: log, "*** Error: %@ ***", error.localizedDescription)
    }
  }
}
