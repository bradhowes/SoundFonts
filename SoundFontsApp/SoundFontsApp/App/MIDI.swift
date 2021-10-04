// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI
import SoundFontsFramework
import os

/**
 Connects to any and all MIDI sources, processing all messages it sees. There really is no API right now. Just create
 an instance and set the `receiver` (aka delegate) to receive the incoming MIDI traffic.
 */
final class MIDI {

  public static var sharedInstance = MIDI()

  private let clientName = "SoundFonts"
  private lazy var inputPortName = clientName + " In"
  private lazy var outputPortName = clientName + " Out"

  private var client: MIDIClientRef = 0
  private var virtualMidiIn: MIDIEndpointRef = 0
  private var inputPort: MIDIPortRef = 0

  private var sources: MIDISources { MIDISources() }
  private var connections = Set<MIDIUniqueID>()

  /// Delegate which will receive incoming MIDI messages
  weak var receiver: MIDIReceiver? {
    didSet {
      os_log(.info, log: log, "MIDI receiver set")
    }
  }

  /**
   Create new instance. Initializes CoreMIDI and creates an input port to receive MIDI traffic
   */
  private init() {

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
    if client != 0 { MIDIClientDispose(client) }
  }
}

extension MIDI {

  private func initialize() {
    enableNetwork()
    guard createVirtualDestination() else { return }
    guard createInputPort() else { return }
    MIDIRestart()
    // updateConnections()
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
    let inactive = connections.subtracting(active.uniqueIds)

    active.forEach { connectSource(endpoint: $0) }
    inactive.forEach { disconnectSource(uniqueId: $0) }
  }

  private func connectSource(endpoint: MIDIEndpointRef) {
    let name = endpoint.displayName
    guard name != outputPortName else {
      os_log(.debug, log: log, "skipping own port '%{public}s'", name)
      return
    }

    let uniqueId = endpoint.uniqueId
    guard !connections.contains(uniqueId) else {
      os_log(.debug, log: log, "already connected to '%{public}s'", name)
      return
    }

    connections.insert(uniqueId)

    var refCon = endpoint
    os_log(.info, log: log, "connecting endpoint %d '%{public}s'", endpoint, endpoint.displayName)
    logErr("MIDIPortConnectSource", MIDIPortConnectSource(inputPort, endpoint, &refCon))
  }

  private func disconnectSource(uniqueId: MIDIUniqueID) {
    guard connections.contains(uniqueId) else {
      os_log(.debug, log: log, "not connected to %d", uniqueId)
      return
    }

    connections.remove(uniqueId)
    guard let endpoint = sources.first(where: { $0.uniqueId == uniqueId }) else { return }

    os_log(.info, log: log, "disconnecting endpoint %d '%{public}s'", endpoint, endpoint.displayName)
    logErr("MIDIPortDisconnectSource", MIDIPortDisconnectSource(inputPort, endpoint))
  }

  private func createVirtualDestination() -> Bool {
    let err = MIDIDestinationCreateWithBlock(client, inputPortName as CFString, &virtualMidiIn) { packetList, _ in
      self.processPackets(packetList: packetList.pointee)
    }
    guard !logErr("MIDIDestinationCreateWithBlock", err) else {
      return false
    }

    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyUniqueID)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyUniqueID, 44_659))
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyAdvanceScheduleTimeMuSec)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyAdvanceScheduleTimeMuSec, 1))
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesClock)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyReceivesClock, 1))
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesNotes)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyReceivesNotes, 1));
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesProgramChanges)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyReceivesProgramChanges, 1));
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyMaxReceiveChannels)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyMaxReceiveChannels, 16));

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

private extension MIDIObjectRef {

  var displayName: String {
    var param: Unmanaged<CFString>?
    let failed = logErr("MIDIObjectGetStringProperty(kMIDIPropertyDisplayName)",
                        MIDIObjectGetStringProperty(self, kMIDIPropertyDisplayName, &param))
    return failed ? "nil" : param!.takeUnretainedValue() as String
  }

  var uniqueId: MIDIUniqueID {
    var param: MIDIUniqueID = 0
    logErr("MIDIObjectGetIntegerProperty(kMIDIPropertyUniqueID)",
           MIDIObjectGetIntegerProperty(self, kMIDIPropertyUniqueID, &param))
    return param
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
  var tag : String {
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
    os_log(.error, log: log, "%{public}s - %d %{public}s", name, err, err.tag)
    return true
  }
  return false
}
