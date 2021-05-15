// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

/**
 Configuration for an alert to be shown to the user.
 */
public struct AlertConfig {
    /// Title of the alert
    let title: String
    /// Message body of the alert
    let message: String
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
            let ac = UIAlertController(title: self.alert.title, message: self.alert.message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.operationCompleted()
            }))
            self.presenter.present(ac, animated: true, completion: nil)
        }
    }

    func operationCompleted() { isFinished = true }
}

/**
 Manager for posting alerts to the user. The plumbing guarantees that only one alert will happen at a time -- others
 will queue until it is their turn to be shown. Although this works, there is the risk of annoying the user with a
 crapload of alerts because of some catastrophic failure.
 */
public final class AlertManager {
    private let queue: OperationQueue = OperationQueue()
    private let presenter: UIViewController
    private var observers: [NSObjectProtocol] = []
    private let notifications: [Notification.Name] = [
        .configLoadFailure,
        .soundFontsCollectionOrphans,
        .soundFontFileAccessDenied,
        .soundFontAddResults
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
            NotificationCenter.default.addObserver(forName: $0, object: nil, queue: nil, using: self.notify)
        }
    }

    private func notify(_ notification: Notification) {
        let (title, body): (String, String) = {
            switch notification.name {
            case .configLoadFailure:
                return (NSLocalizedString("AlertManager_configLoadFailure_title",
                                          comment: "Title of configuration load failure alert"),
                        NSLocalizedString("AlertManager_configLoadFailure_body",
                                          comment: "Body of configuration load failure alert"))

            case .soundFontsCollectionOrphans:
                guard let count = notification.object as? NSNumber else { fatalError() }
                let countLabel = String.localizedStringWithFormat(
                    NSLocalizedString("SF2_file_count", comment: "SF2 file count"), count)
                return (NSLocalizedString("AlertManager_soundFontsCollectionOrphans_title",
                                          comment: "Title of orphaned fonts collection alert"),
                        String(format: NSLocalizedString("AlertManager_soundFontsCollectionOrphans_body",
                                                         comment: "Body of orphaned fonts collection alert"),
                               countLabel))

            case .soundFontFileAccessDenied:
                guard let name = notification.object as? String else { fatalError() }
                return (NSLocalizedString("AlertManager_soundFontFileAccessDenied_title",
                                          comment: "Title of SF2 file access denied alert"),
                        String.localizedStringWithFormat(
                                NSLocalizedString("AlertManager_soundFontFileAccessDenied_body",
                                                  comment: "Body of SF2 file access denied alert"),
                                name))

            default:
                fatalError("unexpected notification - \(notification.name)")
            }
        }()
        post(alert: AlertConfig(title: title, message: body))
    }

    public func post(alert: AlertConfig) {
        queue.addOperation(AlertOperation(alert: alert, presenter: presenter))
    }
}
