// Copyright © 2020 Brad Howes. All rights reserved.

import CoreMIDI
import os

/**
 Connects to any and all MIDI sources, processing all messages it sees. There really is no API right now. Just create
 an instance and set the `receiver` (aka delegate) to receive the incoming MIDI traffic.
 */
public final class MIDI: NSObject {

  public static let maxMidiValue = 12 * 9  // C8

  private let settings: Settings
  private let ourUniqueId: Int32 = 44_659
  private let clientName = "SoundFonts"
  private lazy var inputPortName = clientName

  private var client: MIDIClientRef = MIDIClientRef()
  private var virtualMidiIn: MIDIEndpointRef = MIDIEndpointRef()
  private var virtualMidiOut: MIDIEndpointRef = MIDIEndpointRef()
  private var inputPort: MIDIPortRef = MIDIPortRef()
  private let unknownEndpointRef = MIDIEndpointRef()

  /// Dynamic collection of all of the known MIDI sources
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

  private var sources: MIDISources { MIDISources() }

  /// Mapping all seen MIDI channels (0-based). When a MIDI message with channel info is seen, this mapping is updated
  @objc dynamic public private(set) var channels = [MIDIEndpointRef: UInt8]()

  /// Set of connections from other devices to us.
  @objc dynamic public private(set) var activeConnections = Set<MIDIEndpointRef>()

  private var refConMap: [MIDIEndpointRef: UnsafeMutablePointer<MIDIEndpointRef>] = [:]

  /**
   Current state of a MIDI device
   */
  public struct DeviceState {
    let endpoint: MIDIEndpointRef
    /// Unique ID for the device endpoint to connect to
    let uniqueId: MIDIUniqueID
    /// The display name for the endpoint
    let displayName: String
    /// True if connect to it and able to receive MIDI commands from endpoint
    let autoConnect: Bool
    /// Last seen channel in a MIDI message from this device
    let channel: UInt8?
  }

  /// Obtain current state of MIDI device connections
  public var devices: [DeviceState] {
    MIDISources().map { endpoint in
      let uniqueId = endpoint.uniqueId
      let displayName = endpoint.displayName
      let connected = activeConnections.contains(endpoint)
      let autoConnectDefault = settings.autoConnectNewMIDIDeviceEnabled
      let autoConnect = settings.get(key: connectedSettingKey(for: uniqueId), defaultValue: autoConnectDefault)
      let channel = channels[endpoint]
      os_log(.debug, log: log, "DeviceEntry(%d '%{public}s' %d", uniqueId, displayName, connected)
      return DeviceState(endpoint: endpoint, uniqueId: uniqueId, displayName: displayName, autoConnect: autoConnect,
                         channel: channel)
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
  public init(settings: Settings) {
    self.settings = settings
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
    if virtualMidiOut != MIDIEndpointRef() { MIDIEndpointDispose(virtualMidiOut) }
    if virtualMidiIn != MIDIEndpointRef() { MIDIEndpointDispose(virtualMidiIn) }
    if client != MIDIClientRef() { MIDIClientDispose(client) }
  }

  public func reset() {
    channels.removeAll()
    activeConnections.removeAll()
  }

  public func updateChannel(endpoint: MIDIEndpointRef, channel: UInt8) {
    channels[endpoint] = channel
  }
}

extension MIDI {

  private func initialize() {
    enableNetwork()
    guard createVirtualDestination() else { return }
    // guard createInputPort() else { return }
    MIDIRestart()
  }

  private func createClient() {
    let err = MIDIClientCreateWithBlock(clientName as CFString, &client) {
      let messageID = $0.pointee.messageID
      os_log(.debug, log: log, "MIDIClientCreateWithBlock callback: %{public}s", messageID.tag)
      if messageID  == .msgSetupChanged {
        self.updateConnections()
      }
    }

    loggedErr("MIDIClientCreateWithBlock", err)
  }

  private func updateConnections() {
    os_log(.debug, log: log, "updateConnections")

    let active = sources
    let inactive = activeConnections.subtracting(active)

    active.forEach { establishConnectionIfEnabled(endpoint: $0) }
    inactive.forEach { removeConnection(endpoint: $0) }
  }

  private func establishConnectionIfEnabled(endpoint: MIDIEndpointRef) {
    let name = endpoint.displayName
    let uniqueId = endpoint.uniqueId
    guard uniqueId != ourUniqueId && !activeConnections.contains(endpoint) else {
      os_log(.debug, log: log, "already connected to endpoint %d '%{public}s'", uniqueId, name)
      return
    }

    let key = connectedSettingKey(for: uniqueId)
    let autoConnectDefault = settings.autoConnectNewMIDIDeviceEnabled
    let autoConnect = settings.get(key: key, defaultValue: autoConnectDefault)
    os_log(.debug, log: log, "autoconnect for %{public}s - %d'", key, autoConnect)
    if autoConnect {
      establishConnection(endpoint: endpoint)
    }
  }

  private func connectedSettingKey(for uniqueId: MIDIUniqueID) -> String { "midiAudoConnect_\(uniqueId)" }

  public func connect(endpoint: MIDIEndpointRef) {
    settings.set(key: connectedSettingKey(for: endpoint.uniqueId), value: true)
    establishConnection(endpoint: endpoint)
  }

  public func disconnect(endpoint: MIDIEndpointRef) {
    settings.set(key: connectedSettingKey(for: endpoint.uniqueId), value: false)
    removeConnection(endpoint: endpoint)
  }

  private func establishConnection(endpoint: MIDIEndpointRef) {
    os_log(.debug, log: log, "connecting endpoint %d '%{public}s'", endpoint, endpoint.displayName)

    activeConnections.insert(endpoint)
    let refCon = UnsafeMutablePointer<MIDIEndpointRef>.allocate(capacity: 1)
    refCon.initialize(to: endpoint)

    if loggedErr("MIDIPortConnectSource", MIDIPortConnectSource(virtualMidiIn, endpoint, refCon)) {
      os_log(.error, log: log, "failed to connect to device %{public}s", endpoint.displayName)
      return
    }

    refConMap[endpoint] = refCon
    os_log(.info, log: log, "connected to device %{public}s", endpoint.displayName)
  }

  public func removeConnection(endpoint: MIDIEndpointRef) {
    guard activeConnections.contains(endpoint) else {
      os_log(.debug, log: log, "not connected to %d", endpoint)
      return
    }

    activeConnections.remove(endpoint)
    if let refCon = refConMap.removeValue(forKey: endpoint) {
      refCon.deallocate()
    }

    os_log(.debug, log: log, "disconnecting endpoint %d '%{public}s'", endpoint, endpoint.displayName)
    if loggedErr("MIDIPortDisconnectSource", MIDIPortDisconnectSource(virtualMidiIn, endpoint)) {
      os_log(.error, log: log, "failed to disconnect from device %{public}s", endpoint.displayName)
      return
    }
  }

  private func createVirtualSource() -> Bool {
    let err = MIDISourceCreate(client, inputPortName as CFString, &virtualMidiOut)
    return !loggedErr("MIDISourceCreate", err)
  }

  private func createVirtualDestination() -> Bool {
    if #available(iOS 14.0, *) {
      let err = MIDIDestinationCreateWithProtocol(client, inputPortName as CFString, ._1_0,
                                                  &virtualMidiIn) { [weak self] eventList, refCon in
        guard let self = self else { return }
        let endpoint: MIDIEndpointRef = refCon?.assumingMemoryBound(to: MIDIEndpointRef.self).pointee ?? self.unknownEndpointRef
        self.processPackets(eventList: eventList.pointee, endpoint: endpoint)
      }
      guard !loggedErr("MIDIDestinationCreateWithBlock", err) else {
        return false
      }
    } else {
      let err = MIDIDestinationCreateWithBlock(client, inputPortName as CFString,
                                               &virtualMidiIn) { [weak self] packetList, refCon in
        guard let self = self else { return }
        let endpoint: MIDIEndpointRef = refCon?.assumingMemoryBound(to: MIDIEndpointRef.self).pointee ?? self.unknownEndpointRef
        self.processPackets(packetList: packetList.pointee, endpoint: endpoint)
      }
      guard !loggedErr("MIDIDestinationCreateWithBlock", err) else {
        return false
      }
    }

    loggedErr("MIDIObjectSetIntegerProperty(kMIDIPropertyUniqueID)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyUniqueID, ourUniqueId))
    loggedErr("MIDIObjectSetIntegerProperty(kMIDIPropertyAdvanceScheduleTimeMuSec)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyAdvanceScheduleTimeMuSec, 1))
    loggedErr("MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesClock)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyReceivesClock, 1))
    loggedErr("MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesNotes)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyReceivesNotes, 1))
    loggedErr("MIDIObjectSetIntegerProperty(kMIDIPropertyReceivesProgramChanges)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyReceivesProgramChanges, 1))
    loggedErr("MIDIObjectSetIntegerProperty(kMIDIPropertyMaxReceiveChannels)",
           MIDIObjectSetIntegerProperty(virtualMidiIn, kMIDIPropertyMaxReceiveChannels, 1))

    return true
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

  private func processPackets(packetList: MIDIPacketList, endpoint: MIDIEndpointRef) {
    os_log(.debug, log: log, "processPackets - numPackets: %d endpoint: %d", packetList.numPackets, endpoint)
    packetList.parse(midi: self, receiver: receiver, monitor: activityNotifier, endpoint: endpoint)
  }

  private func processPackets(eventList: MIDIEventList, endpoint: MIDIEndpointRef) {
    os_log(.debug, log: log, "processPackets - numPackets: %d endpoint: %d", eventList.numPackets, endpoint)
    eventList.parse(midi: self, receiver: receiver, monitor: activityNotifier, endpoint: endpoint)
  }
}

private extension MIDIObjectRef {

  var displayName: String {
    var param: Unmanaged<CFString>?
    let failed = loggedErr("MIDIObjectGetStringProperty(kMIDIPropertyDisplayName)",
                           MIDIObjectGetStringProperty(self, kMIDIPropertyDisplayName, &param))
    return failed ? "nil" : param!.takeRetainedValue() as String
  }

  var uniqueId: MIDIUniqueID {
    var param: MIDIUniqueID = MIDIUniqueID()
    loggedErr("MIDIObjectGetIntegerProperty(kMIDIPropertyUniqueID)",
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

/**
 Log an error message if the given `OSStatus` value is not `noErr`.

 - parameter name: the name of the function that return the result
 - parameter err: the result from the funtion
 - returns: `true` if logged
 */
@discardableResult
private func loggedErr(_ name: String, _ err: OSStatus) -> Bool {
  if err != noErr {
    os_log(.error, log: log, "%{public}s - %d %{public}s", name, err, err.tag)
    return true
  }
  return false
}
