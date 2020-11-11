// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

public struct AlertConfig {
    let title: String
    let message: String
    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
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

public final class AlertManager {
    private let queue: OperationQueue = OperationQueue()
    private let presenter: UIViewController
    private var observers: [NSObjectProtocol] = []
    private let notifications: [Notification.Name] = [
        .soundFontsCollectionLoadFailure,
        .soundFontsCollectionOrphans,
        .favoritesCollectionLoadFailure,
        .soundFontFileAccessDenied
    ]

    public init(presenter: UIViewController) {
        self.presenter = presenter
        queue.maxConcurrentOperationCount = 1
        // swiftlint:disable discarded_notification_center_observer
        observers = notifications.map { NotificationCenter.default.addObserver(forName: $0, object: nil, queue: nil, using: self.notify) }
    }

    private func notify(_ notification: Notification) {
        let (title, body): (String, String) = {
            switch notification.name {
            case .soundFontsCollectionLoadFailure:
                return ("Startup Failure", """
Unable to load the last saved sound font collection information. Recreating using found SF2 files, but customizations
have been lost.
""")

            case .favoritesCollectionLoadFailure:
                return ("Startup Failure", "Unable to load the last saved favorites information.")

            case .soundFontsCollectionOrphans:
                guard let count = notification.object as? NSNumber else { fatalError() }
                return ("Orphaned SF2 Files", """
Found \(count.intValue) SF2 files that are not being used and moved them to local SoundFonts folder.
""")

            case .soundFontFileAccessDenied:
                guard let name = notification.object as? String else { fatalError() }
                return ("Access Failure", "Unable to access and use the sound font file '\(name)'.")

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
