// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI
import SoundFontsFramework
import os

/// Connects to any and all MIDI sources, processing all messages it sees. There really is no API right now. Just create
/// an instance and set the controller (aka delegate) to receive the incoming MIDI traffic.
final class MIDI {
  private lazy var log = Logging.logger("MIDI")

  private let clientName = Bundle.main.bundleIdentifier?.localizedLowercase ?? "?"
  private let portName = "SoundFonts"
  private var client: MIDIClientRef = 0

  private var inputPort: MIDIPortRef = 0
  private var outputPort: MIDIPortRef = 0

  private var virtualMidiIn: MIDIEndpointRef = 0
  private var virtualMidiOut: MIDIEndpointRef = 0

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
    if outputPort != 0 { MIDIPortDispose(outputPort) }
    if virtualMidiIn != 0 { MIDIEndpointDispose(virtualMidiIn) }
    if virtualMidiOut != 0 { MIDIEndpointDispose(virtualMidiOut) }
    if client != 0 { MIDIClientDispose(client) }
  }
}

extension MIDI {

  private func initialize() {
    enableNetwork()
    guard createClient() else { return }
    guard createVirtualSource() else { return }
    guard createVirtualDestination() else { return }
    guard createInputPort() else { return }
    guard createOutputPort() else { return }
    connectSourcesToInputPort()
  }

  private func createClient() -> Bool {
    let err = MIDIClientCreateWithBlock(clientName as CFString, &client) { notification in
      self.processNotification(notification: notification.pointee)
    }
    os_log(.info, log: log, "MIDIClientCreateWithBlock: %d - %{public}s", err, name(for: err))
    return err == noErr
  }

  private func setUniqueId(_ endpoint: MIDIEndpointRef, key: SettingKey<Int32>) {
    var uniqueId: Int32 = Settings.shared[key]
    var err = MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyUniqueID, uniqueId)
    os_log(.info, log: log, "MIDIObjectSetIntegerProperty(kMIDIPropertyUniqueID): %d - %{public}s",
           err, name(for: err))
    if err == kMIDIIDNotUnique {
      err = MIDIObjectGetIntegerProperty(virtualMidiOut, kMIDIPropertyUniqueID, &uniqueId)
      os_log(.info, log: log, "MIDIObjectGetIntegerProperty(kMIDIPropertyUniqueID): %d - %{public}s",
             err, name(for: err))
      if err == noErr {
        Settings.shared[key] = uniqueId
      }
    }
  }

  private func createVirtualSource() -> Bool {
    let err = MIDISourceCreate(client, clientName as CFString, &virtualMidiOut)
    os_log(.info, log: log, "MIDISourceCreate: %d - %{public}s", err, name(for: err))
    guard err == noErr else { return false }
    setUniqueId(virtualMidiOut, key: SettingKeys.virtualMidiOutId)
    return true
  }

  private func createVirtualDestination() -> Bool {
    let err = MIDIDestinationCreateWithBlock(client, portName as CFString, &virtualMidiIn) { packetList, _ in
      self.processPackets(packetList: packetList.pointee)
    }
    os_log(.info, log: log, "MIDIDestinationCreateWithBlock: %d - %{public}s", err, name(for: err))
    guard err == noErr else { return false }
    setUniqueId(virtualMidiIn, key: SettingKeys.virtualMidiInId)
    return true
  }

  private func createInputPort() -> Bool {
    let err = MIDIInputPortCreateWithBlock(client, portName as CFString, &inputPort) { packetList, _ in
      self.processPackets(packetList: packetList.pointee)
    }
    os_log(.info, log: log, "MIDIInputPortCreateWithBlock: %d - %{public}s", err, name(for: err))
    return err == noErr
  }

  private func createOutputPort() -> Bool {
    let err = MIDIOutputPortCreate(client, portName as CFString, &outputPort)
    os_log(.info, log: log, "MIDIOutputPortCreateWithBlock: %d - %{public}s", err, name(for: err))
    return err == noErr
  }

  private func connectSourcesToInputPort() {
    let numberOfDevices = MIDIGetNumberOfDevices()
    for deviceIndex in 0..<numberOfDevices {
      let device = MIDIGetDevice(deviceIndex)
      let deviceName = getDisplayName(device)
      os_log(.info, log: log, "visiting device %d: %{public}s", deviceIndex, deviceName)

      let numberOfEntities = MIDIDeviceGetNumberOfEntities(device)
      for entityIndex in 0..<numberOfEntities {
        let entity = MIDIDeviceGetEntity(device, entityIndex)
        let entityName = getDisplayName(entity)
        os_log(.info, log: log, "visiting entity %d: %{public}s", entityIndex, entityName)

        let numberOfSources = MIDIEntityGetNumberOfSources(entity)
        for sourceIndex in 0..<numberOfSources {
          let midiEndPoint = MIDIEntityGetSource(entity, sourceIndex)
          guard midiEndPoint != 0 else { continue }

          let sourceName = getDisplayName(midiEndPoint)
          guard sourceName != clientName else { continue }

          var refCon = midiEndPoint
          let err = MIDIPortConnectSource(inputPort, midiEndPoint, &refCon)
          os_log(.info, log: log, "MIDIPortConnectSource %d %{public}s: %d - %{public}s", sourceIndex, sourceName,
                 err, errorTag[err] ?? "?")
        }
      }
    }
  }

  private func enableNetwork() {
    let mns = MIDINetworkSession.default()
    mns.isEnabled = true
    mns.connectionPolicy = .anyone
    os_log(.debug, log: log, "clientName: %{public}s", clientName)
    os_log(.debug, log: log, "net session enabled: %d", mns.isEnabled)
    os_log(.debug, log: log, "net session networkPort: %d", mns.networkPort)
    os_log(.debug, log: log, "net session networkName: %{public}s", mns.networkName)
    os_log(.debug, log: log, "net session localName: %{public}s", mns.localName)
  }

  private func processNotification(notification: MIDINotification) {
    let info = notificationMessageTag[notification.messageID] ?? "?"
    os_log(.info, log: log, "processNotification: %d - %{public}s", notification.messageID.rawValue, info)
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
    guard err == noErr else {
      os_log(.error, log: log, "error getting device name for %d - %d %{public}s", obj, err, name(for: err))
      return "nil"
    }

    let value = param!.takeRetainedValue() as String
    os_log(.info, log: log, "getDisplayName: %d - %{public}s", obj, value)
    return value
  }

  private func getUniqueId(_ obj: MIDIObjectRef) -> Int32 {
    var param: Int32 = 0
    MIDIObjectGetIntegerProperty(obj, kMIDIPropertyUniqueID, &param)
    return param
  }
}
