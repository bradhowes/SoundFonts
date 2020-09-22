// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit

struct AlertConfig {
    let title: String
    let message: String
}

private final class AlertOperation: Operation {

    private let alert: AlertConfig
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

    init(alert: AlertConfig) {
        self.alert = alert
        super.init()
    }

    override func start() {

        if self.isCancelled {
            self.isFinished = true
            return
        }

        let ac = UIAlertController(title: alert.title, message: alert.message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.operationCompleted()
        }))

        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?.present(ac, animated: true, completion: nil)
        }
    }

    func operationCompleted() { isFinished = true }
}

final class AlertManager {

    static let shared: AlertManager = AlertManager()

    private let queue: OperationQueue = OperationQueue()

    init() {
        queue.maxConcurrentOperationCount = 1
    }

    func post(alert: AlertConfig) {
        queue.addOperation(AlertOperation(alert: alert))
    }
}
