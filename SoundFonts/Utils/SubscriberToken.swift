// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

struct SubscriberToken {

    private let closure: () -> Void

    init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }

    func unsubscribe() {
        closure()
    }
}
