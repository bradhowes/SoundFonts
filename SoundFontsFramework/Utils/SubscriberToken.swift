// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

public struct SubscriberToken {

    private let closure: () -> Void

    public init(_ closure: @escaping () -> Void) {
        self.closure = closure
    }

    public func unsubscribe() {
        closure()
    }
}
