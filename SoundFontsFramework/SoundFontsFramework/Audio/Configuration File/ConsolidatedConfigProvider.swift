// Copyright © 2021 Brad Howes. All rights reserved.

import UIKit
import os.log

/**
 Provider of a ConsolidatedConfig value. This normally comes from a configuration file. Access to the current value is
 to be done through a ConsolidatedConfigFileObserver which will run a closure when the configuration value changes.
 */
public final class ConsolidatedConfigProvider: NSObject {
  private static let log = Logging.logger("ConsolidatedConfigProvider")
  private var log: OSLog { Self.log }

  private let accessQueue = DispatchQueue(label: "ConsolidatedConfigFileQueue", qos: .userInitiated, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .global(qos: .userInitiated))

  private var _config: ConsolidatedConfig?
  private var document: ConsolidatedConfigFileDocument?
  private var documentObserver: NSKeyValueObservation?
  private var stateObserver: NSKeyValueObservation?

  private let fileURL: URL?
  private let identity: Int = UUID().hashValue
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
    os_log(.info, log: Self.log, "init BEGIN")
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

    os_log(.info, log: Self.log, "init END")
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
    os_log(.info, log: log, "%d openDocument BEGIN", identity)

    let document = ConsolidatedConfigFileDocument(identity: identity, contents: config, fileURL: fileURL)
    self.document = document

    NotificationCenter.default.addObserver(self, selector: #selector(processStateChange(_:)),
                                           name: UIDocument.stateChangedNotification, object: document)
    documentObserver = document.observe(\.contents, options: []) { _, _ in
      if let newValue = document.contents {
        self.config = newValue
      }
    }

    document.open { ok in
      if !ok {
        os_log(.error, log: Self.log, "openDocument - failed to open - attempting legacy loading")
        document.attemptLegacyLoad()
      }
    }
    os_log(.info, log: log, "%d openDocument END", identity)
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
    os_log(.info, log: log, "processStateChange: %d", state.rawValue)

    if state == .normal { os_log(.info, log: log, "processStateChange - entered normal state") }
    if state.contains(.closed) { os_log(.info, log: log, "processStateChange - closed") }

    // We look for disable/enable cycles and recreate a new document to absorb new content. This is not really the right
    // thing to do as there is risk of data loss, but the rationale is this: there is only one active document and thus
    // only one active editor for a document. Plus this gets around some serious limitations encountered when trying to
    // keep AUv3 components up-to-date with changes.
    if state.contains(.editingDisabled) {
      os_log(.info, log: log, "processStateChange - editing disabled")
      wasDisabled = true
    } else if wasDisabled {
      os_log(.info, log: log, "processStateChange - editing enabled")
      wasDisabled = false
      openDocument()
    }

    if state.contains(.inConflict) {
      os_log(.info, log: log, "processStateChange - conflict was detected")
      resolveDocumentConflict(document: document)
    }

    if state.contains(.savingError) {
      os_log(.info, log: log, "processStateChange - failed to save document")
      openDocument()
    }

    handleDocStateForTransfers(state: state)
  }

  func handleDocStateForTransfers(state: UIDocument.State) {
    if transferring {
      if state.contains(.progressAvailable) {
        os_log(.info, log: log, "handleDocStateForTransfers - transfer is done")
        transferring = false
      }
    } else if state.contains(.progressAvailable) {
      os_log(.info, log: log, "handleDocStateForTransfers - transfer is in progress")
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
    os_log(.info, log: log, "%d willResignActiveNotification BEGIN", identity)
    guard let document = self.document else { return }

    self.documentObserver = nil
    self.document = nil

    if document.hasUnsavedChanges {
      document.save(to: document.fileURL, for: .forOverwriting) { ok in
        os_log(.info, log: self.log, "%d willResignActiveNotification - save ok %d", self.identity, ok)
        document.close { ok in
          os_log(.info, log: self.log, "%d willResignActiveNotification - close ok %d", self.identity, ok)
        }
      }
    } else {
      document.close { ok in
        os_log(.info, log: self.log, "%d willResignActiveNotification - close ok %d", self.identity, ok)
      }
    }
    os_log(.info, log: log, "%d willResignActiveNotification END", identity)
  }

  /**
   Notification that the application/host is entering the foreground state. We create a new document to load any changes
   that may have taken place in the config file since we resigned active state.

   - parameter notification: the notification that fired
   */
  @objc func willEnterForegroundNotification(_ notification: Notification) {
    os_log(.info, log: log, "%d willEnterForegroundNotification BEGIN", identity)
    self.openDocument()
    os_log(.info, log: log, "%d willEnterForegroundNotification END", identity)
  }
}
