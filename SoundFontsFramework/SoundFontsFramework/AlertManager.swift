// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import os.log

/// Configuration for an alert to be shown to the user.
public struct AlertConfig {
  /// Title of the alert
  let title: String
  /// Message body of the alert
  let body: String
}

private final class AlertOperation: Operation {

  private let alert: AlertConfig
  private let presenter: UIViewController

  private var _finished: Bool = false

  override var isFinished: Bool {
    get { _finished }
    set {
      willChangeValue(forKey: "isFinished")
      _finished = newValue
      didChangeValue(forKey: "isFinished")
    }
  }

  override var isAsynchronous: Bool { true }

  init(alert: AlertConfig, presenter: UIViewController) {
    self.alert = alert
    self.presenter = presenter
    super.init()
  }

  override func start() {
    if self.isCancelled {
      self.isFinished = true
      return
    }

    DispatchQueue.main.async {
      let ac = UIAlertController(
        title: self.alert.title, message: self.alert.body, preferredStyle: .alert)
      ac.addAction(
        UIAlertAction(
          title: "OK", style: .default,
          handler: { _ in
            self.operationCompleted()
          }))
      self.presenter.present(ac, animated: true, completion: nil)
    }
  }

  func operationCompleted() { isFinished = true }
}

/// Manager for posting alerts to the user. The plumbing guarantees that only one alert will happen at a time -- others
/// will queue until it is their turn to be shown. Although this works, there is the risk of annoying the user with a
/// crapload of alerts because of some catastrophic failure.
public final class AlertManager {
  private let log = Logging.logger("AlertManager")

  private let queue: OperationQueue = OperationQueue()
  private weak var presenter: UIViewController?
  private var observers: [NSObjectProtocol] = []
  private let notifications: [Notification.Name] = [
    .configLoadFailure,
    .soundFontsCollectionOrphans,
    .soundFontFileAccessDenied,
    .synthStartFailure
  ]

  /**
   Construct a new manager that uses the given view controller for presenting new alerts. Watch for certain
   notifications to fire, and post an alert when they do.

   - parameter presenter: the view controller to use for presenting
   */
  public init(presenter: UIViewController) {
    self.presenter = presenter
    queue.maxConcurrentOperationCount = 1
    observers = notifications.map {
      NotificationCenter.default.addObserver(
        forName: $0, object: nil, queue: nil, using: self.notify)
    }
  }

  private func notify(_ notification: Notification) {
    os_log(.debug, log: log, "notify BEGIN - %{public}s", notifications.description)
    let alertConfig: AlertConfig = {
      switch notification.name {
      case .configLoadFailure: return configLoadFailureAlert()
      case .soundFontsCollectionOrphans:
        return soundFontsCollectionOrphansAlert(count: notification.intObject)
      case .soundFontFileAccessDenied:
        return soundFontFileAccessDeniedAlert(name: notification.urlObject.lastPathComponent)
      case .synthStartFailure:
        return synthStartFailureAlert(failure: notification.synthStartFailureObject)
      default: fatalError("unexpected notification - \(notification.name)")
      }
    }()
    post(alert: alertConfig)
  }

  /**
   Post an alert to the user

   - parameter alert: the contents of the alert to show
   */
  public func post(alert: AlertConfig) {
    guard let presenter = self.presenter else { return }
    os_log(.debug, log: log, "post BEGIN")
    queue.addOperation(AlertOperation(alert: alert, presenter: presenter))
    os_log(.debug, log: log, "post END")
  }
}

extension Notification {
  fileprivate var intObject: Int {
    guard let tmp = object as? NSNumber else { fatalError() }
    return tmp.intValue
  }

  fileprivate var urlObject: URL {
    guard let tmp = object as? URL else { fatalError() }
    return tmp
  }

  fileprivate var stringObject: String {
    guard let tmp = object as? String else { fatalError() }
    return tmp
  }

  fileprivate var synthStartFailureObject: SynthStartFailure {
    guard let tmp = object as? SynthStartFailure else { fatalError() }
    return tmp
  }
}

extension AlertManager {

  private func configLoadFailureAlert() -> AlertConfig {
    let (title, body) = Formatters.strings.configLoadFailureAlert
    return AlertConfig(title: title, body: body)
  }

  private func soundFontsCollectionOrphansAlert(count: Int) -> AlertConfig {
    let countLabel = Formatters.format(fileCount: count)
    let strings = Formatters.strings.soundFontFileAccessDeniedAlert
    return AlertConfig(title: strings.0, body: String(format: strings.1, countLabel))
  }

  private func soundFontFileAccessDeniedAlert(name: String) -> AlertConfig {
    let strings = Formatters.strings.soundFontFileAccessDeniedAlert
    let format = strings.1
    let body = String(format: format, name)
    return AlertConfig(title: strings.0, body: body)
  }

  private func synthStartFailureAlert(failure: SynthStartFailure) -> AlertConfig {
    let title = Formatters.strings.synthStartFailureTitle
    switch failure {
    case .noSynth:
      return AlertConfig(title: title, body: Formatters.strings.noSynthFailureBody)
    case .engineStarting(let error):
      return AlertConfig(
        title: title,
        body: String(
          format: Formatters.strings.engineStartingFailureBody,
          error.localizedDescription))
    case .presetLoading(let error):
      return AlertConfig(
        title: title,
        body: String(
          format: Formatters.strings.patchLoadingFailureBody,
          error.localizedDescription))
    case .sessionActivating(let error):
      return AlertConfig(
        title: title,
        body: String(
          format: Formatters.strings.sessionActivatingFailureBody,
          error.localizedDescription))
    }
  }
}
