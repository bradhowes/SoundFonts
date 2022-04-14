// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os.log

/**
 Provider of a ConsolidatedConfig value. This normally comes from a configuration file. Access to the current value is
 to be done through a ConsolidatedConfigFileObserver which will run a closure when the configuration value changes.
 */
public final class ConsolidatedConfigProvider: NSObject {
  private let accessQueue = DispatchQueue(label: "ConsolidatedConfigFileQueue", qos: .userInitiated, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .global(qos: .userInitiated))

  private let log: OSLog
  private var _config: ConsolidatedConfig?
  private var document: ConsolidatedConfigDocument?
  private var documentObserver: NSKeyValueObservation?
  private var stateObserver: NSKeyValueObservation?

  public let identity: Int = UUID().hashValue
  private let fileURL: URL?
  private var wasDisabled = false
  private var transferring = false

  /// The value that comes from the document. Access to it is serialized via the `accessQueue` so it should be safe to
  /// access it from any thread.
  @objc dynamic public var config: ConsolidatedConfig? {
    get { accessQueue.sync { self._config } }
    set { accessQueue.sync { self._config = newValue } }
  }

  /**
   Obtain the configuration contents from a configuration file.

   - parameter fileURL: the location for the document
   */
  public init(inApp: Bool, fileURL: URL? = nil) {
    let log = Logging.logger("ConsolidatedConfigProvider[\(identity)]")
    os_log(.debug, log: log, "init BEGIN - %{public}s", fileURL.descriptionOrNil)

    self.log = log
    self.fileURL = fileURL
    super.init()

    if inApp {
      NotificationCenter.default.addObserver(self, selector: #selector(willResignActiveNotification(_:)),
                                             name: UIApplication.willResignActiveNotification,
                                             object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification(_:)),
                                             name: UIApplication.willEnterForegroundNotification,
                                             object: nil)
    } else {
      NotificationCenter.default.addObserver(self, selector: #selector(willResignActiveNotification(_:)),
                                             name: NSNotification.Name.NSExtensionHostWillResignActive,
                                             object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification(_:)),
                                             name: NSNotification.Name.NSExtensionHostWillEnterForeground,
                                             object: nil)
    }

    openDocument()

    os_log(.debug, log: log, "init END")
  }

  /**
   Flag the configuration as having been changed so that the system will save it to disk.
   */
  public func markAsChanged() {
    document?.updateChangeCount(.done)
  }

  /**
   Create a new UIDocument object to get the latest configuration file contents.
   */
  private func openDocument() {
    os_log(.debug, log: log, "openDocument BEGIN")

    let document = ConsolidatedConfigDocument(identity: identity, contents: config, fileURL: fileURL)
    document.open { ok in
      if ok {
        self.useDocument(document)
        return
      }

      self.handleOpenFailure(document)
    }
  }

  private func handleOpenFailure(_ document: ConsolidatedConfigDocument) {
    os_log(.info, log: self.log, "handleOpenFailure BEGIN")
    document.attemptLegacyLoad { ok in
      if ok {
        os_log(.info, log: self.log, "handleOpenFailure - using document")
        self.useDocument(document)
      } else {
        os_log(.error, log: self.log, "handleOpenFailure - failed to get initial content")
        fatalError()
      }
    }
    os_log(.debug, log: log, "handleOpenFailure END")
  }

  private func useDocument(_ document: ConsolidatedConfigDocument) {
    os_log(.info, log: self.log, "useDocument BEGIN")
    self.document = document
    NotificationCenter.default.addObserver(self, selector: #selector(self.processStateChange(_:)),
                                           name: UIDocument.stateChangedNotification, object: document)
    documentObserver = document.observe(\.contents, options: []) { _, _ in
      if let newValue = document.contents {
        self.config = newValue
      }
    }

    if let contents = document.contents {
      self.config = contents
    } else {
      self.config = nil
    }

    os_log(.info, log: self.log, "useDocument END")
  }
}

// MARK: - State tracking

private extension ConsolidatedConfigProvider {

  /**
   Notification that the current document changed state.

   - parameter state: notification
   */
  @objc func processStateChange(_ notification: Notification) {
    guard let document = self.document else { return }
    let state = document.documentState
    os_log(.debug, log: log, "processStateChange: %d", state.rawValue)

    if state == .normal { os_log(.debug, log: log, "processStateChange - entered normal state") }
    if state.contains(.closed) { os_log(.debug, log: log, "processStateChange - closed") }

    // We look for disable/enable cycles and recreate a new document to absorb new content. This is not really the right
    // thing to do as there is risk of data loss, but the rationale is this: there is only one active document and thus
    // only one active editor for a document. Plus this gets around some serious limitations encountered when trying to
    // keep AUv3 components up-to-date with changes.
    if state.contains(.editingDisabled) {
      os_log(.debug, log: log, "processStateChange - editing disabled")
      wasDisabled = true
    } else if wasDisabled {
      os_log(.debug, log: log, "processStateChange - editing enabled")
      wasDisabled = false
      openDocument()
    }

    if state.contains(.inConflict) {
      os_log(.debug, log: log, "processStateChange - conflict was detected")
      resolveDocumentConflict(document: document)
    }

    handleDocStateForTransfers(state: state)
  }

  func handleDocStateForTransfers(state: UIDocument.State) {
    if transferring {
      if state.contains(.progressAvailable) {
        os_log(.debug, log: log, "handleDocStateForTransfers - transfer is done")
        transferring = false
      }
    } else if state.contains(.progressAvailable) {
      os_log(.debug, log: log, "handleDocStateForTransfers - transfer is in progress")
      transferring = true
    }
  }

  func resolveDocumentConflict(document: UIDocument) {
    do {
      try NSFileVersion.removeOtherVersionsOfItem(at: document.fileURL)
      if let conflictingVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: document.fileURL) {
        for version in conflictingVersions {
          version.isResolved = true
        }
      }
    } catch let error {
      os_log(.error, log: log, "resolveDocumentConflict *** Error: %@ ***", error.localizedDescription)
    }
  }
}

// MARK: - App-state change handlers

private extension ConsolidatedConfigProvider {

  /**
   Notification that the application/host is no longer the active app. We save any changes and we release the document
   that was used to load the content.

   - parameter notification: the notification that fired
   */
  @objc func willResignActiveNotification(_ notification: Notification) {
    os_log(.debug, log: log, "willResignActiveNotification BEGIN")
    guard let document = self.document else { return }

    self.documentObserver = nil
    self.document = nil

    if document.hasUnsavedChanges {
      document.save(to: document.fileURL, for: .forOverwriting) { ok in
        os_log(.debug, log: self.log, "willResignActiveNotification - save ok %d", ok)
        document.close { ok in
          os_log(.debug, log: self.log, "willResignActiveNotification - close ok %d", ok)
        }
      }
    } else {
      document.close { ok in
        os_log(.debug, log: self.log, "willResignActiveNotification - close ok %d", ok)
      }
    }
    os_log(.debug, log: log, "willResignActiveNotification END")
  }

  /**
   Notification that the application/host is entering the foreground state. We create a new document to load any changes
   that may have taken place in the config file since we resigned active state.

   - parameter notification: the notification that fired
   */
  @objc func willEnterForegroundNotification(_ notification: Notification) {
    os_log(.debug, log: log, "willEnterForegroundNotification BEGIN")
    self.openDocument()
    os_log(.debug, log: log, "willEnterForegroundNotification END")
  }
}
