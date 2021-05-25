// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

/**
 Type of value returned by SubscriptionManager.subscribe. Knows how to unsubscribe themselves.
 */
public protocol SubscriberToken {

    /**
     Unsubscribe from the SubscriptionManager.
     */
    func unsubscribe()
}
