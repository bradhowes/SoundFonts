//
//  InfoBarMIDINotifier.swift
//  SoundFontsFramework
//
//  Created by Brad Howes on 31/03/2023.
//  Copyright © 2023 Brad Howes. All rights reserved.
//

import CoreMIDI
import MorkAndMIDI

public class MIDIMonitor {

  public final class MIDIActivityNotifier: NSObject {

    public struct Payload: CustomStringConvertible {
      public var description: String { "\(uniqueId),\(channel)" }
      let uniqueId: MIDIUniqueID
      let channel: Int
    }

    private let notification = TypedNotification<Payload>(name: "MIDIActivity")
    private let serialQueue = DispatchQueue(label: "MIDIActivity", qos: .userInteractive, attributes: [],
                                            autoreleaseFrequency: .inherit, target: .global(qos: .userInteractive))
    private var lastChannel: Int = -2
    private var lastNotificationTime: Date = .distantPast

    public func addMonitor(block: @escaping (Payload) -> Void) -> NotificationObserver {
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

  private let settings: Settings
  private let activityNotifier = MIDIActivityNotifier()

  public init(settings: Settings) {
    self.settings = settings
  }

  public func addMonitor(block: @escaping (MIDIActivityNotifier.Payload) -> Void) -> NotificationObserver {
    activityNotifier.addMonitor(block: block)
  }
}

extension MIDIMonitor: Monitor {

  public func shouldConnect(to endpoint: MIDIEndpointRef) -> Bool {
    return true
  }

  public func didSee(uniqueId: MIDIUniqueID, group: Int, channel: Int) {
    activityNotifier.showActivity(uniqueId: uniqueId, channel: channel)
  }
}

extension MIDIMonitor {
  public func didInitialize(uniqueId: MIDIUniqueID) {}
  public func willUninitialize() {}
  public func didCreate(inputPort: MIDIPortRef) {}
  public func willDelete(inputPort: MIDIPortRef) {}
  public func didStart() {}
  public func didStop() {}
  public func didConnect(to endpoint: MIDIEndpointRef) {}
  public func willUpdateConnections() {}
  public func didUpdateConnections(connected: any Sequence<MIDIEndpointRef>, disappeared: any Sequence<MIDIUniqueID>) {}

}
