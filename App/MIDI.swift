// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import SoundFontsFramework
import CoreMIDI
import os

/**
 Connects to any and all MIDI sources, processing all messages it sees. There really is no API right now. Just create an instance and
 set the controller (aka delegate) to receive the incoming MIDI traffic.
 */
final class MIDI {
    private let log = Logging.logger("MIDI")

    private let clientName = Bundle.main.bundleID
    private let portName = "SoundFontAppIn"
    private var client: MIDIClientRef = 0
    private var inputPort: MIDIPortRef = 0

    /// Delegate which will receive incoming MIDI messages
    weak var controller: MIDIController?

    public enum MsgKind: UInt8 {
        case noteOff               = 0x80
        case noteOn                = 0x90
        case polyphonicKeyPressure = 0xA0
        case controlChange         = 0xB0 // also channelMode messages
        case programChange         = 0xC0
        case channelPressure       = 0xD0
        case pitchBendChange       = 0xE0
        case systemExclusive       = 0xF0
        case midiTimeCode          = 0xF1
        case songPosition          = 0xF2
        case songSelect            = 0xF3
        case tuneRequest           = 0xF6
        case endSystemExclusive    = 0xF7
        case timingClock           = 0xF8
        case sequenceStart         = 0xFA
        case sequenceContinue      = 0xFB
        case sequenceStop          = 0xFC
        case activeSensing         = 0xFE
        case reset                 = 0xFF

        init?(_ value: UInt8) {
            let command = value & 0xF0
            self.init(rawValue: command == 0xF0 ? value : command)
        }

        var hasChannel: Bool { self.rawValue < 0xF0 }
    }

    private let msgSizes: [MsgKind: Int] = [
        .noteOff: 2,
        .noteOn: 2,
        .polyphonicKeyPressure: 2,
        .controlChange: 2,
        .programChange: 1,
        .channelPressure: 1,
        .pitchBendChange: 2,
        .midiTimeCode: 1,
        .songPosition: 2,
        .songSelect: 1
    ]

    private func msgSize(for kind: MsgKind) -> Int { msgSizes[kind] ?? 0 }

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
        kMIDINotPermitted: "kMIDINotPermitted"
    ]

    private let notificationMessageTag: [MIDINotificationMessageID: String] = [
        .msgSetupChanged: "some aspect of the current MIDI setup changed",
        .msgObjectAdded: "system added a device, entity, or endpoint",
        .msgObjectRemoved: "system removed a device, entity, or endpoint",
        .msgPropertyChanged: "object’s property value changed",
        .msgThruConnectionsChanged: "system created or destroyed a persistent MIDI Thru connection",
        .msgSerialPortOwnerChanged: "system changed a serial port owner",
        .msgIOError: "driver I/O error occurred"
    ]

    private func name(for status: OSStatus) -> String { errorTag[status] ?? "?" }

    /**
     Create new instance. Initializes CoreMIDI and creates an input port to receive MIDI traffic
     */
    init() {
        enableNetwork()

        var err = MIDIClientCreateWithBlock(clientName as CFString, &client) { notification in self.processNotification(notification: notification.pointee) }
        os_log(.info, log: log, "MIDIClientCreateWithBlock: %d - %{public}s", err, name(for: err))
        guard err == noErr else { return }

        err = MIDIInputPortCreateWithBlock(client, portName as CFString, &inputPort) { packetList, _ in self.processPackets(packetList: packetList.pointee) }
        os_log(.info, log: log, "MIDIInputPortCreateWithBlock: %d - %{public}s", err, name(for: err))
        guard err == noErr else { return }

        connectSourcesToInputPort()
    }

    deinit {
        if inputPort != 0 { MIDIPortDispose(inputPort) }
        if client != 0 { MIDIClientDispose(client) }
    }
}

extension MIDI {

    private func connectSourcesToInputPort() {
        let sourceCount = MIDIGetNumberOfSources()
        for srcIndex in 0 ..< sourceCount {
            let midiEndPoint = MIDIGetSource(srcIndex)
            let err = MIDIPortConnectSource(inputPort, midiEndPoint, nil)
            os_log(.info, log: log, "MIDIPortConnectSource %d %{public}s: %d - %{public}s", srcIndex, getDisplayName(midiEndPoint), err, errorTag[err] ?? "?")
        }
    }

    private func enableNetwork() {
        let mns = MIDINetworkSession.default()
        mns.isEnabled = true
        mns.connectionPolicy = .anyone
        os_log(.info, log: log, "net session enabled: %d", mns.isEnabled)
        os_log(.info, log: log, "net session networkPort: %d", mns.networkPort)
        os_log(.info, log: log, "net session networkName: %{public}s", mns.networkName)
        os_log(.info, log: log, "net session localName: %{public}s", mns.localName)
    }

    private func processNotification(notification: MIDINotification) {
        let info = notificationMessageTag[notification.messageID] ?? "?"
        os_log(.info, log: log, "processNotification: %d - %{public}s", notification.messageID.rawValue, info)
        if notification.messageID == .msgObjectAdded || notification.messageID == .msgSetupChanged {
            connectSourcesToInputPort()
        }
    }

    private func processPackets(packetList: MIDIPacketList) {
        guard let controller = self.controller else { return }
        MIDIParser.parse(packetList: packetList, for: controller)
    }
}

extension MIDI {

    private func getDisplayName(_ obj: MIDIObjectRef) -> String {
        guard obj != 0 else { return "nil" }
        var param: Unmanaged<CFString>?
        let err = MIDIObjectGetStringProperty(obj, kMIDIPropertyDisplayName, &param)
        if err != noErr {
            os_log(.error, log: log, "error getting device name for %d - %d %{public}s", obj, err, name(for: err))
            return "nil"
        }

        let value = param!.takeRetainedValue() as String
        os_log(.info, log: log, "getDisplayName: %d - %{public}s", obj, value)
        return value
    }

    private var destinationNames: [String] { (0..<MIDIGetNumberOfDestinations()).compactMap { getDisplayName(MIDIGetDestination($0)) } }
    private var sourceNames: [String] { (0..<MIDIGetNumberOfSources()).compactMap { getDisplayName(MIDIGetSource($0)) } }

    private func showMIDIObjectType(_ ot: MIDIObjectType) {
        switch ot {
        case .other: os_log("midiObjectType: Other", log: log, type: .debug)
        case .device: os_log("midiObjectType: Device", log: log, type: .debug)
        case .entity: os_log("midiObjectType: Entity", log: log, type: .debug)
        case .source: os_log("midiObjectType: Source", log: log, type: .debug)
        case .destination: os_log("midiObjectType: Destination", log: log, type: .debug)
        case .externalDevice: os_log("midiObjectType: ExternalDevice", log: log, type: .debug)
        case .externalEntity: os_log("midiObjectType: ExternalEntity", log: log, type: .debug)
        case .externalSource: os_log("midiObjectType: ExternalSource", log: log, type: .debug)
        case .externalDestination: os_log("midiObjectType: ExternalDestination", log: log, type: .debug)
        @unknown default: fatalError()
        }
    }

    //    private func notifyBlock(midiNotification: UnsafePointer<MIDINotification>) {
    //        print("\ngot a MIDINotification!")
    //
    //        let notification = midiNotification.pointee
    //        print("MIDI Notify, messageId= \(notification.messageID)")
    //        print("MIDI Notify, messageSize= \(notification.messageSize)")
    //
    //        switch notification.messageID {
    //
    //        // Some aspect of the current MIDISetup has changed.  No data.  Should ignore this  message if messages 2-6 are handled.
    //        case .msgSetupChanged:
    //            print("MIDI setup changed")
    //            let ptr = UnsafeMutablePointer<MIDINotification>(mutating: midiNotification)
    //            let obj = ptr.pointee
    //            print(obj)
    //            print("id \(obj.messageID)")
    //            print("size \(obj.messageSize)")
    //
    //        // A device, entity or endpoint was added. Structure is MIDIObjectAddRemoveNotification.
    //        case .msgObjectAdded:
    //            print("added")
    //            midiNotification.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) {
    //                let obj = $0.pointee
    //                print(obj)
    //                print("id \(obj.messageID)")
    //                print("size \(obj.messageSize)")
    //                print("child \(obj.child)")
    //                print("child type \(obj.childType)")
    //                showMIDIObjectType(obj.childType)
    //                print("parent \(obj.parent)")
    //                print("parentType \(obj.parentType)")
    //                showMIDIObjectType(obj.parentType)
    //                print("childName \(String(describing: getDisplayName(obj.child)))")
    //            }
    //
    //        // A device, entity or endpoint was removed. Structure is MIDIObjectAddRemoveNotification.
    //        case .msgObjectRemoved:
    //            print("kMIDIMsgObjectRemoved")
    //            midiNotification.withMemoryRebound(to: MIDIObjectAddRemoveNotification.self, capacity: 1) {
    //                let obj = $0.pointee
    //                print(obj)
    //                print("id \(obj.messageID)")
    //                print("size \(obj.messageSize)")
    //                print("child \(obj.child)")
    //                print("child type \(obj.childType)")
    //                print("parent \(obj.parent)")
    //                print("parentType \(obj.parentType)")
    //                print("childName \(String(describing: getDisplayName(obj.child)))")
    //            }
    //
    //        // An object's property was changed. Structure is MIDIObjectPropertyChangeNotification.
    //        case .msgPropertyChanged:
    //            print("kMIDIMsgPropertyChanged")
    //            midiNotification.withMemoryRebound(to: MIDIObjectPropertyChangeNotification.self, capacity: 1) {
    //                let obj = $0.pointee
    //                print(obj)
    //                print("id \(obj.messageID)")
    //                print("size \(obj.messageSize)")
    //                print("object \(obj.object)")
    //                print("objectType \(obj.objectType)")
    //                print("propertyName \(obj.propertyName)")
    //                print("propertyName \(obj.propertyName.takeUnretainedValue())")
    //                if obj.propertyName.takeUnretainedValue() as String == "apple.midirtp.session" {
    //                    print("connected")
    //                }
    //            }
    //
    //        //     A persistent MIDI Thru connection wasor destroyed.  No data.
    //        case .msgThruConnectionsChanged:
    //            print("MIDI thru connections changed.")
    //
    //        //A persistent MIDI Thru connection was created or destroyed.  No data.
    //        case .msgSerialPortOwnerChanged:
    //            print("MIDI serial port owner changed.")
    //
    //        case .msgIOError:
    //            print("MIDI I/O error.")
    //            midiNotification.withMemoryRebound(to: MIDIIOErrorNotification.self, capacity: 1) {
    //                let obj = $0.pointee
    //                print(obj)
    //                print("id \(obj.messageID)")
    //                print("size \(obj.messageSize)")
    //                print("driverDevice \(obj.driverDevice)")
    //                print("errorCode \(obj.errorCode)")
    //            }
    //
    //        @unknown default:
    //            fatalError()
    //        }
    //    }
}
