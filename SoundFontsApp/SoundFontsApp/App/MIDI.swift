// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI
import SoundFontsFramework
import os

/**
 Connects to any and all MIDI sources, processing all messages it sees. There really is no API right now. Just create
 an instance and set the controller (aka delegate) to receive the incoming MIDI traffic.
 */
final class MIDI {

  private let clientName = "SoundFonts"
  private lazy var inputPortName = clientName + " In"
  private lazy var outputPortName = clientName + " Out"

  private var client: MIDIClientRef = 0
  private var virtualMidiIn: MIDIEndpointRef = 0
  private var virtualMidiOut: MIDIEndpointRef = 0
  private var inputPort: MIDIPortRef = 0

  private var sources: MIDISources { MIDISources() }
  private var connections = Set<MIDIEndpointRef>()

  /// Delegate which will receive incoming MIDI messages
  weak var receiver: MIDIReceiver? {
    didSet {
      os_log(.info, log: log, "MIDI receiver set")
    }
  }

  /**
   Create new instance. Initializes CoreMIDI and creates an input port to receive MIDI traffic
   */
  init() {

    // Create client here -- doing it in initialize causes it to not work.
    createClient()
    DispatchQueue.global(qos: .userInitiated).async { self.initialize() }
  }

  /**
   Tear down MIDI plumbing.
   */
  deinit {
    if inputPort != 0 { MIDIPortDispose(inputPort) }
    if virtualMidiIn != 0 { MIDIEndpointDispose(virtualMidiIn) }
    if virtualMidiOut != 0 { MIDIEndpointDispose(virtualMidiOut) }
    if client != 0 { MIDIClientDispose(client) }
  }
}

extension MIDI {

  private func initialize() {
    enableNetwork()
    guard createVirtualSource() else { return }
    guard createVirtualDestination() else { return }
    guard createInputPort() else { return }
    updateConnections()
  }

  private func createClient() {
    let err = MIDIClientCreateWithBlock(clientName as CFString, &client) {
      let messageID = $0.pointee.messageID
      os_log(.debug, log: log, "client callback: %{public}s", messageID.tag)
      if messageID  == .msgSetupChanged {
        self.updateConnections()
      }
    }

    logErr("MIDIClientCreateWithBlock", err)
  }

  private func updateConnections() {
    os_log(.info, log: log, "updateConnections")

    let active = sources
    let inactive = connections.subtracting(active)

    active.forEach { connectSource(endpoint: $0) }
    inactive.forEach { disconnectSource(endpoint: $0) }
  }

  private func connectSource(endpoint: MIDIEndpointRef) {
    let name = endpoint.displayName
    guard name != outputPortName else { return}
    guard !connections.contains(endpoint) else { return }

    connections.insert(endpoint)
    var refCon = endpoint
    os_log(.info, log: log, "connecting endpoint %d '%{public}s'", endpoint, endpoint.displayName)
    logErr("MIDIPortConnectSource", MIDIPortConnectSource(inputPort, endpoint, &refCon))
  }

  private func disconnectSource(endpoint: MIDIEndpointRef) {
    guard connections.contains(endpoint) else { return }

    connections.remove(endpoint)
    os_log(.info, log: log, "disconnecting endpoint %d '%{public}s'", endpoint, endpoint.displayName)
    logErr("MIDIPortDisconnectSource", MIDIPortDisconnectSource(inputPort, endpoint))
  }

  private func createVirtualSource() -> Bool {
    guard !logErr("MIDISourceCreate", MIDISourceCreate(client, outputPortName as CFString, &virtualMidiOut)) else {
      return false
    }
    virtualMidiOut.setUniqueId(key: SettingKeys.virtualMidiOutId)
    return true
  }

  private func createVirtualDestination() -> Bool {
    let err = MIDIDestinationCreateWithBlock(client, inputPortName as CFString, &virtualMidiIn) { packetList, _ in
      self.processPackets(packetList: packetList.pointee)
    }
    guard !logErr("MIDIDestinationCreateWithBlock", err) else {
      return false
    }
    virtualMidiIn.setUniqueId(key: SettingKeys.virtualMidiInId)
    return true
  }

  private func createInputPort() -> Bool {
    let err = MIDIInputPortCreateWithBlock(client, inputPortName as CFString, &inputPort) { packetList, _ in
      self.processPackets(packetList: packetList.pointee)
    }
    logErr("MIDIInputPortCreatWithBlock", err)
    return err == noErr
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

  private func processPackets(packetList: MIDIPacketList) {
    guard let receiver = self.receiver else { return }
    MIDIParser.parse(packetList: packetList, for: receiver)
  }
}

private struct MIDISources: Collection {
  typealias Index = Int
  typealias Element = MIDIEndpointRef

  var startIndex: Index { 0 }
  var endIndex: Index { MIDIGetNumberOfSources() }

  var displayNames: [String] { map { $0.displayName } }
  var uniqueIds: [MIDIUniqueID] { map { $0.uniqueId } }

  init() {}

  func index(after index: Index) -> Index { index + 1 }
  subscript (index: Index) -> Element { MIDIGetSource(index) }
}

extension MIDIObjectRef {

  var displayName: String {
    var param: Unmanaged<CFString>?
    let failed = logErr("MIDIObjectGetStringProperty",
                        MIDIObjectGetStringProperty(self, kMIDIPropertyDisplayName, &param))
    return failed ? "nil" : param!.takeUnretainedValue() as String
  }

  var uniqueId: MIDIUniqueID {
    var param: MIDIUniqueID = 0
    logErr("MIDIObjectGetIntegerProperty", MIDIObjectGetIntegerProperty(self, kMIDIPropertyUniqueID, &param))
    return param
  }

  fileprivate func setUniqueId(key: SettingKey<Int32>) {
    var uniqueId: Int32 = Settings.shared[key]
    var err = MIDIObjectSetIntegerProperty(self, kMIDIPropertyUniqueID, uniqueId)
    logErr("MIDIObjectSetIntegerProperty", err)
    if err == kMIDIIDNotUnique {
      err = MIDIObjectGetIntegerProperty(self, kMIDIPropertyUniqueID, &uniqueId)
      logErr("MIDIObjectGetIntegerProperty", err)
      if err == noErr {
        Settings.shared[key] = uniqueId
      }
    }
  }
}

private extension MIDINotificationMessageID {
  var tag: String {
    switch self {
    case .msgSetupChanged: return "msgSetupChanged"
    case .msgObjectAdded: return "msgObjectAdded"
    case .msgObjectRemoved: return "msgObjectRemoved"
    case .msgPropertyChanged: return "msgPropertyChanged"
    case .msgIOError: return "msgIOError"
    case .msgThruConnectionsChanged: return "msgThruConnectionsChanged"
    case .msgSerialPortOwnerChanged: return "msgSerialPortOwnerChanged"
    @unknown default: fatalError()
    }
  }
}

private let log = Logging.logger("MIDI")

private extension OSStatus {
  var errorTag : String {
    switch self {
    case noErr: return "OK"
    case kMIDIInvalidClient: return "kMIDIInvalidClient"
    case kMIDIInvalidPort: return "kMIDIInvalidPort"
    case kMIDIWrongEndpointType: return "kMIDIWrongEndpointType"
    case kMIDINoConnection: return "kMIDINoConnection"
    case kMIDIUnknownEndpoint: return "kMIDIUnknownEndpoint"
    case kMIDIUnknownProperty: return "kMIDIUnknownProperty"
    case kMIDIWrongPropertyType: return "kMIDIWrongPropertyType"
    case kMIDINoCurrentSetup: return "kMIDINoCurrentSetup"
    case kMIDIMessageSendErr: return "kMIDIMessageSendErr"
    case kMIDIServerStartErr: return "kMIDIServerStartErr"
    case kMIDISetupFormatErr: return "kMIDISetupFormatErr"
    case kMIDIWrongThread: return "kMIDIWrongThread"
    case kMIDIObjectNotFound: return "kMIDIObjectNotFound"
    case kMIDIIDNotUnique: return "kMIDIIDNotUnique"
    case kMIDINotPermitted: return "kMIDINotPermitted"
    default: return "???"
    }
  }
}

@discardableResult
private func logErr(_ name: String, _ err: OSStatus) -> Bool {
  if err != noErr {
    os_log(.error, log: log, "%{public}s - %d %{public}s", name, err, err.errorTag)
    return true
  }
  return false
}
