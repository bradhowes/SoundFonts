// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI
import SoundFontsFramework
import os

/// Connects to any and all MIDI sources, processing all messages it sees. There really is no API right now. Just create
/// an instance and set the controller (aka delegate) to receive the incoming MIDI traffic.
final class MIDI {
  private let log = Logging.logger("MIDI")

  private let clientName = Bundle.main.bundleID
  private let portName = "SoundFonts"
  private var client: MIDIClientRef = 0
  private var inputPort: MIDIPortRef = 0
  private var virtualEndpoint: MIDIEndpointRef = 0

  /// Delegate which will receive incoming MIDI messages
  weak var receiver: MIDIReceiver? {
    didSet {
      os_log(.info, log: log, "receiver set")
    }
  }

  private let errorTag: [OSStatus: String] = [
    noErr: "",
    kMIDIInvalidClient: "kMIDIInvalidClient",
    kMIDIInvalidPort: "kMIDIInvalidPort",
    kMIDIWrongEndpointType: "kMIDIWrongEndpointType",
    kMIDINoConnection: "kMIDINoConnection",
    kMIDIUnknownEndpoint: "kMIDIUnknownEndpoint",
    kMIDIUnknownProperty: "kMIDIUnknownProperty",
    kMIDIWrongPropertyType: "kMIDIWrongPropertyType",
    kMIDINoCurrentSetup: "kMIDINoCurrentSetup",
    kMIDIMessageSendErr: "kMIDIMessageSendErr",
    kMIDIServerStartErr: "kMIDIServerStartErr",
    kMIDISetupFormatErr: "kMIDISetupFormatErr",
    kMIDIWrongThread: "kMIDIWrongThread",
    kMIDIObjectNotFound: "kMIDIObjectNotFound",
    kMIDIIDNotUnique: "kMIDIIDNotUnique",
    kMIDINotPermitted: "kMIDINotPermitted",
  ]

  private let notificationMessageTag: [MIDINotificationMessageID: String] = [
    .msgSetupChanged: "some aspect of the current MIDI setup changed",
    .msgObjectAdded: "system added a device, entity, or endpoint",
    .msgObjectRemoved: "system removed a device, entity, or endpoint",
    .msgPropertyChanged: "object’s property value changed",
    .msgThruConnectionsChanged: "system created or destroyed a persistent MIDI Thru connection",
    .msgSerialPortOwnerChanged: "system changed a serial port owner",
    .msgIOError: "driver I/O error occurred",
  ]

  private func name(for status: OSStatus) -> String { errorTag[status] ?? "?" }

  /**
     Create new instance. Initializes CoreMIDI and creates an input port to receive MIDI traffic
     */
  init() {
    DispatchQueue.global(qos: .background).async { self.initialize() }
  }

  /**
     Tear down MIDI plumbing.
     */
  deinit {
    if inputPort != 0 { MIDIPortDispose(inputPort) }
    if virtualEndpoint != 0 { MIDIEndpointDispose(virtualEndpoint) }
    if client != 0 { MIDIClientDispose(client) }
  }
}

extension MIDI {

  private func initialize() {
    enableNetwork()

    var err = MIDIClientCreateWithBlock(clientName as CFString, &client) { notification in
      self.processNotification(notification: notification.pointee)
    }
    os_log(.info, log: log, "MIDIClientCreateWithBlock: %d - %{public}s", err, name(for: err))
    guard err == noErr else { return }

    err = MIDIInputPortCreateWithBlock(client, portName as CFString, &inputPort) { packetList, _ in
      self.processPackets(packetList: packetList.pointee)
    }
    os_log(.info, log: log, "MIDIInputPortCreateWithBlock: %d - %{public}s", err, name(for: err))
    guard err == noErr else { return }

    err = MIDIDestinationCreateWithBlock(client, portName as CFString, &virtualEndpoint) {
      packetList, _ in
      self.processPackets(packetList: packetList.pointee)
    }
    os_log(.info, log: log, "MIDIDestinationCreateWithBlock: %d - %{public}s", err, name(for: err))
    guard err == noErr else { return }

    var uniqueId = Settings.shared.midiVirtualDestinationId
    err = MIDIObjectSetIntegerProperty(virtualEndpoint, kMIDIPropertyUniqueID, uniqueId)
    os_log(
      .info, log: log, "MIDIObjectSetIntegerProperty(kMIDIPropertyUniqueID): %d - %{public}s", err,
      name(for: err))
    if err == kMIDIIDNotUnique {
      err = MIDIObjectGetIntegerProperty(virtualEndpoint, kMIDIPropertyUniqueID, &uniqueId)
      os_log(
        .info, log: log, "MIDIObjectGetIntegerProperty(kMIDIPropertyUniqueID): %d - %{public}s",
        err,
        name(for: err))
      if err == noErr {
        Settings.shared.midiVirtualDestinationId = uniqueId
      }
    }

    err = MIDIObjectSetIntegerProperty(virtualEndpoint, kMIDIPropertyAdvanceScheduleTimeMuSec, 1)
    os_log(
      .info, log: log,
      "MIDIObjectSetIntegerProperty(kMIDIPropertyAdvanceScheduleTimeMuSec): %d - %{public}s",
      err, name(for: err))

    err = MIDIObjectSetIntegerProperty(inputPort, kMIDIPropertyAdvanceScheduleTimeMuSec, 1)
    os_log(
      .info, log: log,
      "MIDIObjectSetIntegerProperty(kMIDIPropertyAdvanceScheduleTimeMuSec): %d - %{public}s",
      err, name(for: err))

    connectSourcesToInputPort()
  }

  private func connectSourcesToInputPort() {
    let sourceCount = MIDIGetNumberOfSources()
    for srcIndex in 0..<sourceCount {
      let midiEndPoint = MIDIGetSource(srcIndex)
      if midiEndPoint != 0 {
        let err = MIDIPortConnectSource(inputPort, midiEndPoint, nil)
        os_log(
          .debug, log: log, "MIDIPortConnectSource %d %{public}s: %d - %{public}s", srcIndex,
          getDisplayName(midiEndPoint), err, errorTag[err] ?? "?")
      }
    }
  }

  private func enableNetwork() {
    let mns = MIDINetworkSession.default()
    mns.isEnabled = true
    mns.connectionPolicy = .anyone
    os_log(.debug, log: log, "net session enabled: %d", mns.isEnabled)
    os_log(.debug, log: log, "net session networkPort: %d", mns.networkPort)
    os_log(.debug, log: log, "net session networkName: %{public}s", mns.networkName)
    os_log(.debug, log: log, "net session localName: %{public}s", mns.localName)
  }

  private func processNotification(notification: MIDINotification) {
    let info = notificationMessageTag[notification.messageID] ?? "?"
    os_log(
      .info, log: log, "processNotification: %d - %{public}s", notification.messageID.rawValue, info
    )
    if notification.messageID == .msgObjectAdded || notification.messageID == .msgSetupChanged {
      connectSourcesToInputPort()
    }
  }

  private func processPackets(packetList: MIDIPacketList) {
    guard let receiver = self.receiver else { return }
    MIDIParser.parse(packetList: packetList, for: receiver)
  }

  private func getDisplayName(_ obj: MIDIObjectRef) -> String {
    guard obj != 0 else { return "nil" }
    var param: Unmanaged<CFString>?
    let err = MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &param)
    if err != noErr {
      os_log(
        .error, log: log, "error getting device name for %d - %d %{public}s", obj, err,
        name(for: err))
      return "nil"
    }

    let value = param!.takeRetainedValue() as String
    os_log(.info, log: log, "getDisplayName: %d - %{public}s", obj, value)
    return value
  }
}
