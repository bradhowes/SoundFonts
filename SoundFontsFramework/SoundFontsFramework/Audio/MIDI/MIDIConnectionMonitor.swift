// Copyright © 2023 Brad Howes. All rights reserved.

import CoreMIDI
import MorkAndMIDI
import os.log

public final class MIDIConnectionMonitor {
  private lazy var log: Logger = Logging.logger("MIDIMonitor")

  private let settings: Settings
  private let connectionActivityNotifier = ConnectionActivityNotifier()
  private var connectionStates = [MIDIUniqueID: MIDIConnectionState]()

  public init(settings: Settings) {
    self.settings = settings
  }

  public struct ConnectionActivityPayload: CustomStringConvertible {
    public var description: String { "\(uniqueId), \(channel)" }
    let uniqueId: MIDIUniqueID
    let channel: Int
  }

  public func addConnectionActivityMonitor(block: @escaping (ConnectionActivityPayload) -> Void) -> NotificationObserver {
    connectionActivityNotifier.addMonitor(block: block)
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

private extension MIDIConnectionMonitor {
  func connectedSettingKey(for uniqueId: MIDIUniqueID) -> String { "midiAutoConnect_\(uniqueId)" }
  func fixedVelocitySettingKey(for uniqueId: MIDIUniqueID) -> String { "midFixedVelocity_\(uniqueId)" }
}

// MARK: - Monitor Protocol

extension MIDIConnectionMonitor: Monitor {

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
    connectionActivityNotifier.showActivity(uniqueId: uniqueId, channel: channel)
  }
}

extension MIDIConnectionMonitor {
  public func didInitialize() {}
  public func willUninitialize() {}
  public func willDelete(inputPort: MIDIPortRef) {}
  public func didStart() {}
  public func didStop() {}
  public func didConnect(to uniqueId: MIDIUniqueID) {}
  public func willUpdateConnections() {
  }
  public func didUpdateConnections(connected: any Sequence<MIDIEndpointRef>, disappeared: any Sequence<MIDIUniqueID>) {}
}

private final class ConnectionActivityNotifier {
  let queueName = "MIDIMonitor.ConnectionActivity"
  var lastChannel: Int = -2
  var lastNotificationTime: Date = .distantPast
  let notification: TypedNotification<MIDIConnectionMonitor.ConnectionActivityPayload>
  let serialQueue: DispatchQueue

  init() {
    notification = .init(name: queueName)
    serialQueue = .init(label: "MIDIActivity", qos: .userInteractive, attributes: [],
                        autoreleaseFrequency: .inherit, target: .global(qos: .userInteractive))
  }

  internal func addMonitor(block: @escaping (MIDIConnectionMonitor.ConnectionActivityPayload) -> Void) -> NotificationObserver {
    notification.registerOnMain(block: block)
  }

  internal func showActivity(uniqueId: MIDIUniqueID, channel: Int) {
    let now = Date()
    if channel != lastChannel || now.timeIntervalSince(lastNotificationTime) > 0.5 {
      lastNotificationTime = now
      lastChannel = channel
      serialQueue.async { self.notification.post(value: .init(uniqueId: uniqueId, channel: channel)) }
    }
  }
}
