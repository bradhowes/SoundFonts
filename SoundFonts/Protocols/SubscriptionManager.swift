// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation

public class SubscriptionManager<Event>
{
    typealias Subscription = (Event)->Void

    private var subscriptions = [UUID: Subscription]()

    @discardableResult
    func subscribe<O:AnyObject>(_ subscriber: O, closure: @escaping (Event)->Void) -> SubscriberToken {
        let uuid = UUID()
        let token = SubscriberToken { [weak self] in self?.subscriptions.removeValue(forKey: uuid) }
        subscriptions[uuid] = { [weak subscriber] kind in
            if subscriber != nil {
                closure(kind)
            }
            else {
                token.unsubscribe()
            }
        }
        return token
    }

    func notify(_ event: Event) {
        subscriptions.values.forEach { $0(event) }
    }
}
