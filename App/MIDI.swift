// Copyright © 2020 Brad Howes. All rights reserved.

import UIKit
import SoundFontsFramework
import CoreMIDI

/**
 Plays notes from keyboard using Sampler and shows the note values being played on InfoBar.
 */
final class MIDI {

    let clientName = "SoundFontsApp"
    let portName = "SoundFontAppIn"
    let destinationName = "SoundFontAppIn"

    var notifyProc: MIDINotifyProc = { (msg: UnsafePointer<MIDINotification>, refCon: UnsafeMutableRawPointer?) in }
    var readProc: MIDIReadProc = { (msg: UnsafePointer<MIDIPacketList>, readProcRefCon: UnsafeMutableRawPointer?,
        srcConnRefCon: UnsafeMutableRawPointer?) in
    }

    var client: MIDIClientRef = 0
    var inputPort: MIDIPortRef = 0
    var destination: MIDIEndpointRef = 0

    init?() {
        MIDIClientCreateWithBlock(clientName as CFString, &client) { (msg: UnsafePointer<MIDINotification>) in
            self.processNotification(msg.pointee)
        }

        let status = MIDIInputPortCreateWithBlock(
            client, portName as CFString,
            &inputPort) { (msg: UnsafePointer<MIDIPacketList>, _: UnsafeMutableRawPointer?) in
                self.processMessages(msg.pointee)
        }

        print(status)

        guard status == noErr else { return nil }
    }

    deinit {
        MIDIClientDispose(client)
    }

    func processNotification(_ msg: MIDINotification) {
        print("***", msg.messageID, msg.messageSize)
    }

    func processMessages(_ msgs: MIDIPacketList) {
        print("*** received messages")
    }
}
