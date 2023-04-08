// Copyright © 2023 Brad Howes. All rights reserved.

import CoreMIDI
import MorkAndMIDI

public final class MIDIMonitor {
  private lazy var log = Logging.logger("MIDIMonitor")

  private let settings: Settings
  private let activityNotifier = ActivityNotifier()
  private var connectionStates = [MIDIUniqueID: MIDIConnectionState]()

  public init(settings: Settings) {
    self.settings = settings
  }

  public struct Payload: CustomStringConvertible {
    public var description: String { "\(uniqueId),\(channel)" }
    let uniqueId: MIDIUniqueID
    let channel: Int
  }

  public func addMonitor(block: @escaping (Payload) -> Void) -> NotificationObserver {
    activityNotifier.addMonitor(block: block)
  }

  public func connectionState(for uniqueId: MIDIUniqueID) -> MIDIConnectionState {
    if let found = connectionStates[uniqueId] {
      return found
    } else {
      let state: MIDIConnectionState = .init()
      let setting = settings.get(key: fixedVelocitySettingKey(for: uniqueId), defaultValue: 128)
      state.fixedVelocity = (setting > 0 && setting < 128) ? UInt8(setting) : nil
      self.connectionStates[uniqueId] = state
      return state
    }
  }

  public func setAutoConnectState(for uniqueId: MIDIUniqueID, autoConnect: Bool) {
    settings.set(key: connectedSettingKey(for: uniqueId), value: autoConnect)
  }

  public func setFixedVelocityState(for uniqueId: MIDIUniqueID, velocity: UInt8?) {
    connectionStates[uniqueId]?.fixedVelocity = velocity
    settings.set(key: fixedVelocitySettingKey(for: uniqueId), value: velocity ?? 128)
  }
}

private extension MIDIMonitor {
  func connectedSettingKey(for uniqueId: MIDIUniqueID) -> String { "midiAutoConnect_\(uniqueId)" }
  func fixedVelocitySettingKey(for uniqueId: MIDIUniqueID) -> String { "midFixedVelocity_\(uniqueId)" }
}

// MARK: - Monitor Protocol

extension MIDIMonitor: Monitor {

  public func didCreate(inputPort: MIDIPortRef) {
    // Save our unique ID if CoreMIDI had to change it due to a conflict.
    var uniqueId: Int32 = 0
    guard MIDIObjectGetIntegerProperty(inputPort, kMIDIPropertyUniqueID, &uniqueId) == noErr else { return }
    guard Int(uniqueId) != settings[.midiInputPortUniqueId] else { return }
    settings[.midiInputPortUniqueId] = Int(uniqueId)
  }

  public func shouldConnect(to uniqueId: MIDIUniqueID) -> Bool {
    let autoConnectDefault = settings.autoConnectNewMIDIDeviceEnabled
    let autoConnect = settings.get(key: connectedSettingKey(for: uniqueId), defaultValue: autoConnectDefault)
    return autoConnect
  }

  public func didSee(uniqueId: MIDIUniqueID, group: Int, channel: Int) {
    connectionState(for: uniqueId).channel = UInt8(channel + 1)
    activityNotifier.showActivity(uniqueId: uniqueId, channel: channel)
  }
}

extension MIDIMonitor {
  public func didInitialize() {}
  public func willUninitialize() {}
  public func willDelete(inputPort: MIDIPortRef) {}
  public func didStart() {}
  public func didStop() {}
  public func didConnect(to uniqueId: MIDIUniqueID) {}
  public func willUpdateConnections() {}
  public func didUpdateConnections(connected: any Sequence<MIDIEndpointRef>, disappeared: any Sequence<MIDIUniqueID>) {}
}

private final class ActivityNotifier: NSObject {

  private let notification = TypedNotification<MIDIMonitor.Payload>(name: "MIDIActivity")
  private let serialQueue = DispatchQueue(label: "MIDIActivity", qos: .userInteractive, attributes: [],
                                          autoreleaseFrequency: .inherit, target: .global(qos: .userInteractive))
  private var lastChannel: Int = -2
  private var lastNotificationTime: Date = .distantPast

  public func addMonitor(block: @escaping (MIDIMonitor.Payload) -> Void) -> NotificationObserver {
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
