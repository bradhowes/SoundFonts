// Copyright © 2023 Brad Howes. All rights reserved.

import CoreMIDI
import MorkAndMIDI

public final class MIDIMonitor {
  private lazy var log = Logging.logger("MIDIMonitor")

  public final class ActivityNotifier: NSObject {

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
  private let activityNotifier = ActivityNotifier()

  public init(settings: Settings) {
    self.settings = settings
  }

  public func addMonitor(block: @escaping (ActivityNotifier.Payload) -> Void) -> NotificationObserver {
    activityNotifier.addMonitor(block: block)
  }

  public func setAutoConnectState(for uniqueId: MIDIUniqueID, autoConnect: Bool) {
    settings.set(key: connectedSettingKey(for: uniqueId), value: autoConnect)
  }

  private func connectedSettingKey(for uniqueId: MIDIUniqueID) -> String { "midiAudoConnect_\(uniqueId)" }
}

extension MIDIMonitor: Monitor {

  public func shouldConnect(to uniqueId: MIDIUniqueID) -> Bool {
    let autoConnectDefault = settings.autoConnectNewMIDIDeviceEnabled
    let autoConnect = settings.get(key: connectedSettingKey(for: uniqueId), defaultValue: autoConnectDefault)
    return autoConnect
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
  public func didConnect(to uniqueId: MIDIUniqueID) {}
  public func willUpdateConnections() {}
  public func didUpdateConnections(connected: any Sequence<MIDIEndpointRef>, disappeared: any Sequence<MIDIUniqueID>) {}

}
