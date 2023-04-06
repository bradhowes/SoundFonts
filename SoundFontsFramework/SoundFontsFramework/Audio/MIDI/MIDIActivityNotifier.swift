// Copyright © 2023 Brad Howes. All rights reserved.

import CoreMIDI

public final class MIDIActivityNotifier: NSObject {

  public struct Data: CustomStringConvertible {
    public var description: String { "\(uniqueId),\(channel)" }

    let uniqueId: MIDIUniqueID
    let channel: Int
  }

  private let notification = TypedNotification<Data>(name: "MIDIActivity")
  private let serialQueue = DispatchQueue(label: "MIDIActivity", qos: .userInteractive, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .global(qos: .userInteractive))
  private var lastChannel: Int = -2
  private var lastNotificationTime: Date = .distantPast

  public func addMonitor(block: @escaping (Data) -> Void) -> NotificationObserver {
    notification.registerOnMain(block: block)
  }

  public func showActivity(uniqueId: MIDIUniqueID, channel: Int) {
    let now = Date()
    if channel != lastChannel || now.timeIntervalSince(lastNotificationTime) > 0.5 {
      lastNotificationTime = now
      lastChannel = channel
      serialQueue.async { self.notification.post(value: .init(uniqueId: uniqueId, channel: channel)) }
    }
  }
}
