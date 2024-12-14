// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os.log

private let notificationQueueQoS = DispatchQoS.userInitiated
private let notificationQueue = DispatchQueue.global(qos: notificationQueueQoS.qosClass)

/**
 Manages subscriptions to event notifications. Events can be anything but are usually defined as an enum. When an
 event happens, call the `notify` method to send the event to all subscribers. Notifications happen asynchronously
 on the `main` thread.
 */
public class SubscriptionManager<Event: CustomStringConvertible> {
  private let log = Logging.logger("SubscriptionManager")

  /// The type of function / closure that is used to subscribe to a subscription manager
  public typealias NotifierProc = (Event) -> Void

  /// The type of function / closure that is used to unsubscribe to a subscription manager
  public typealias UnsubscribeProc = () -> Void

  /// Serial request queue to protect the `subscriptions` map. The notifications will be done async on the
  /// `notificationsQueue`.
  private let subscriptionsQueue = DispatchQueue(label: "SubscriptionsManagerQueue", qos: notificationQueueQoS,
                                                 target: notificationQueue)
  private var subscriptions = [UUID: NotifierProc]()

  private struct Token: SubscriberToken {
    private let unsubscribeProc: UnsubscribeProc
    fileprivate init(_ unsubscribeProc: @escaping UnsubscribeProc) {
      self.unsubscribeProc = unsubscribeProc
    }
    public func unsubscribe() { unsubscribeProc() }
  }

  private var lastEvent: Event?
  private let cacheEvent: Bool

  /**
   Construct a new subscription manager

   - parameter cacheEvent: when true, hold onto the last event and use it when there are new subscriptions
   */
  public init(_ cacheEvent: Bool = false) { self.cacheEvent = cacheEvent }

  /**
   Establish a connection between the SubscriptionManager and the notifier such that any future Events will be sent
   to the notifier.

   - parameter subscriber: the object that is subscribing -- if it dies, then the subscription is automatically
   removed.
   - parameter notifier: the closure to invoke for each new Event
   - returns: a token that knows how to unsubscribe
   */
  @discardableResult
  public func subscribe<O: AnyObject>(_ subscriber: O, notifier: @escaping NotifierProc) -> SubscriberToken {
    let uuid = UUID()

    // The token knows how to remove a subscription.
    let token = Token { [weak self] in
      guard let self = self else { return }
      _ = self.subscriptionsQueue.sync { self.subscriptions.removeValue(forKey: uuid) }
    }

    self.subscriptionsQueue.sync {

      // Add a new subscription that can handle when the subscriber goes away and unsubscribe it.
      self.subscriptions[uuid] = { [weak subscriber] kind in
        if subscriber != nil {
          notifier(kind)
        } else {
          token.unsubscribe()
        }
      }
    }

    // Send the last event that was received if caching is enabled.
    if let event = lastEvent, cacheEvent {
      notifier(event)
    }

    return token
  }

  /**
   Notify all subscribers of a new event.

   - parameter event: the event that just took place
   */
  @discardableResult
  public func notify(_ event: Event) -> Int {
    os_log(.debug, log: log, "notify BEGIN - %{public}s", event.description)
    if cacheEvent { lastEvent = event }
    return subscriptionsQueue.sync {
      subscriptions.values.forEach { closure in
#if DELAY_NOTIFICATIONS // see Development.xcconfig
        let delay = Int.random(in: 100...3000)
        notificationQueue.asyncAfter(deadline: .now() + .milliseconds(delay)) { closure(event) }
#else
        notificationQueue.async { closure(event) }
#endif
      }
      return subscriptions.count
    }
  }

  public func runOnNotifyQueue(_ closure: @escaping () -> Void) {
    notificationQueue.async { closure() }
  }
}
