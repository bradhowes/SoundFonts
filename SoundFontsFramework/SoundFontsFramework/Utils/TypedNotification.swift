// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

/// Typed notification definition. Template argument defines the type of a value that will be transmitted in the
/// notification userInfo["value"] slot. This value will be available to blocks registered to receive it
open class TypedNotification<ValueType: CustomStringConvertible>: Tasking {
  private let log = Logging.logger("TypedNotification")

  /// The name of the notification
  public let name: Notification.Name

  /**
   Construct a new notification definition.

   - parameter name: the unique name for the notification
   */
  public required init(name: Notification.Name) { self.name = name }

  /**
   Construct a new notification definition.

   - parameter name: the unique name for the notification
   */
  public convenience init(name: String) { self.init(name: Notification.Name(name)) }

  /**
   Post this notification to all observers of it

   - parameter value: the value to forward to the observers
   */
  open func post(value: ValueType) {
    os_log(.info, log: log, "post")
    NotificationCenter.default.post(name: name, object: nil, userInfo: ["value": value])
  }

  /**
   Register an observer to receive this notification definition.

   - parameter block: a closure to execute when this kind of notification arrives
   - returns: a NotificationObserver instance that records the registration.
   */
  open func registerOnAny(block: @escaping (ValueType) -> Void) -> NotificationObserver {
    NotificationObserver(notification: self, block: block)
  }

  /**
   Register for a notification that *only* takes place on the app's main (UI) thread.

   - parameter block: a closure to execute when this kind of notification arrives
   - returns: a NotificationObserver instance that records the registration.
   */
  open func registerOnMain(block: @escaping (ValueType) -> Void) -> NotificationObserver {
    NotificationObserver(notification: self) { arg in Self.onMain { block(arg) } }
  }
}

/// Manager of a TypedNotification registration. When the instance is no longer being held, it will automatically
/// unregister the internal observer from future notification events.
public class NotificationObserver {
  private let name: Notification.Name
  private var observer: NSObjectProtocol?

  /**
   Create a new observer for the given typed notification
   */
  public init<ValueType>(notification: TypedNotification<ValueType>, block aBlock: @escaping (ValueType) -> Void) {
    name = notification.name
    observer = NotificationCenter.default.addObserver(forName: notification.name, object: nil, queue: nil) { note in
      guard let value = note.userInfo?["value"] as? ValueType else { fatalError("Couldn't understand user info") }
      aBlock(value)
    }
  }

  /**
   Force the observer to forget its observation reference (something that happens automatically if/when the observer
   is no longer held by another object).
   */
  public func forget() {
    guard let observer = self.observer else { return }
    NotificationCenter.default.removeObserver(observer)
    self.observer = nil
  }

  /**
   Cleanup notification registration by removing our internal observer from notifications.
   */
  deinit {
    forget()
  }
}
