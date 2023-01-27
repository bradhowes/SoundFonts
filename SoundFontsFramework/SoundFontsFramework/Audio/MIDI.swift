// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI
import os

/**
 Connects to any and all MIDI sources, processing all messages it sees. There really is no API right now. Just create
 an instance and set the `receiver` (aka delegate) to receive the incoming MIDI traffic.
 */
public final class MIDI: NSObject {

  public static var sharedInstance = MIDI()
  public static let maxMidiValue = 12 * 9  // C8

  private let ourUniqueId: Int32 = 44_659
  private let clientName = "SoundFonts"
  private lazy var inputPortName = clientName + " In"

  private var client: MIDIClientRef = MIDIClientRef()
  private var virtualMidiIn: MIDIEndpointRef = MIDIEndpointRef()
  private var inputPort: MIDIPortRef = MIDIPortRef()
  private var sources: MIDISources { MIDISources() }

  @objc dynamic
  public private(set) var channels = [MIDIUniqueID: UInt8]()

  @objc dynamic
  public private(set) var activeConnections = Set<MIDIUniqueID>()

  /**
   Current state of a MIDI device
   */
  public struct DeviceState {
    /// Unique ID for the device endpoint to connect to
    let uniqueId: MIDIUniqueID
    /// The display name for the endpoint
    let displayName: String
    /// True if connected to it and able to receive MIDI commands from endpoint
    let connected: Bool
    /// Last seen channel in a MIDI message from this device
    let channel: UInt8?
  }

  /// Obtain current state of MIDI device connections
  public var devices: [DeviceState] {
    MIDISources().map { endpoint in
      let uniqueId = endpoint.uniqueId
      let displayName = endpoint.displayName
      let connected = activeConnections.contains(uniqueId)
      let channel = channels[uniqueId]
      os_log(.debug, log: log, "DeviceEntry(%d '%{public}s' %d", uniqueId, displayName, connected)
      return DeviceState(uniqueId: uniqueId, displayName: displayName, connected: connected, channel: channel)
    }
  }

  /// Delegate which will receive incoming MIDI messages
  public weak var receiver: AnyMIDIReceiver? {
    didSet {
      os_log(.debug, log: log, "MIDI receiver set")
    }
  }

  private let activityNotifier = MIDIActivityNotifier()

  /**
   Create new instance. Initializes CoreMIDI and creates an input port to receive MIDI traffic
   */
  private override init() {
    super.init()
    // Create client here -- doing it in initialize() does not work.
    createClient()
    DispatchQueue.global(qos: .userInitiated).async { self.initialize() }
  }

  public func addMonitor(block: @escaping (MIDIActivityNotifier.Data) -> Void) -> NotificationObserver {
    activityNotifier.addMonitor(block: block)
  }

  /**
   Tear down MIDI plumbing.
   */
  deinit {
    if inputPort != MIDIPortRef() { MIDIPortDispose(inputPort) }
    if virtualMidiIn != MIDIEndpointRef() { MIDIEndpointDispose(virtualMidiIn) }
    if client != MIDIClientRef() { MIDIClientDispose(client) }
  }

  public func updateChannel(uniqueId: MIDIUniqueID, channel: UInt8) {
    channels[uniqueId] = channel
  }
}

extension MIDI {

  private func initialize() {
    enableNetwork()
    guard createVirtualDestination() else { return }
    guard createInputPort() else { return }
    MIDIRestart()
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
    os_log(.debug, log: log, "updateConnections")

    let active = sources
    let inactive = activeConnections.subtracting(active.uniqueIds)

    active.forEach { connectSource(endpoint: $0) }
    inactive.forEach { disconnectSource(uniqueId: $0) }
  }

  private func connectSource(endpoint: MIDIEndpointRef) {
    let name = endpoint.displayName
    let uniqueId = endpoint.uniqueId
    guard uniqueId != ourUniqueId && !activeConnections.contains(uniqueId) else {
      os_log(.debug, log: log, "already connected to endpoint %d '%{public}s'", uniqueId, name)
      return
    }

    activeConnections.insert(uniqueId)

    let refCon = UnsafeMutablePointer<MIDIUniqueID>.allocate(capacity: 1)
    refCon.initialize(to: uniqueId)

    os_log(.debug, log: log, "connecting endpoint %d '%{public}s'", uniqueId, name)
    logErr("MIDIPortConnectSource", MIDIPortConnectSource(inputPort, endpoint, refCon))
  }

  private func disconnectSource(uniqueId: MIDIUniqueID) {
    guard activeConnections.contains(uniqueId) else {
      os_log(.debug, log: log, "not connected to %d", uniqueId)
      return
    }

    activeConnections.remove(uniqueId)
    guard let endpoint = sources.first(where: { $0.uniqueId == uniqueId }) else {
      os_log(.error, log: log, "unable to disconnect - no endpoint with uniqueId %d", uniqueId)
      return
    }

    os_log(.debug, log: log, "disconnecting endpoint %d '%{public}s'", uniqueId, endpoint.displayName)
    logErr("MIDIPortDisconnectSource", MIDIPortDisconnectSource(inputPort, endpoint))
  }

  private func createVirtualDestination() -> Bool {
    let err = MIDIDestinationCreateWithBlock(client, inputPortName as CFString,
                                             &virtualMidiIn) { [weak self] packetList, uniqueId in
      guard let self = self else { return }
      guard let uniqueId = uniqueId?.assumingMemoryBound(to: MIDIUniqueID.self).pointee else { fatalError() }
      self.processPackets(packetList: packetList.pointee, uniqueId: uniqueId)
    }
    guard !logErr("MIDIDestinationCreateWithBlock", err) else {
      return false
    }

    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyUniqueID)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyUniqueID, ourUniqueId))
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyAdvanceScheduleTimeMuSec)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyAdvanceScheduleTimeMuSec, 1))
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesClock)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyReceivesClock, 1))
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesNotes)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyReceivesNotes, 1))
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesProgramChanges)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyReceivesProgramChanges, 1))
    logErr("MIDIObjectSetIntegerProperty(kMIDIPropertyMaxReceiveChannels)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyMaxReceiveChannels, 16))

    return true
  }

  private func createInputPort() -> Bool {
    let err = MIDIInputPortCreateWithBlock(client, inputPortName as CFString,
                                           &inputPort) { [weak self] packetList, uniqueId in
      guard let self = self else { return }
      guard let uniqueId = uniqueId?.assumingMemoryBound(to: MIDIUniqueID.self).pointee else { fatalError() }
      self.processPackets(packetList: packetList.pointee, uniqueId: uniqueId)
    }

    logErr("MIDIInputPortCreateWithBlock", err)
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

  private func processPackets(packetList: MIDIPacketList, uniqueId: MIDIUniqueID) {
    os_log(.debug, log: log, "processPackets - numPackets: %d uniqueId: %d", packetList.numPackets, uniqueId)
    packetList.parse(receiver: receiver, monitor: activityNotifier, uniqueId: uniqueId)
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
    return failed ? "nil" : param!.takeRetainedValue() as String
  }

  var uniqueId: MIDIUniqueID {
    var param: MIDIUniqueID = MIDIUniqueID()
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
  var tag: String {
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
