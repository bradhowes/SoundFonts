// Copyright © 2020 Brad Howes. All rights reserved.

import os

public final class MIDIController {
    private lazy var log = Logging.logger("MIDIController")

    public let messageQueue: DispatchQueue
    public var channel: Int { settings.midiChannel }

    private let selectedFontControllerId = UInt8(112)
    private let selectedPresetControllerId = UInt8(114)

    private let keyboard: Keyboard?
    private let selectSoundFontControl: SelectSoundFontControl

    public init(keyboard: Keyboard?, selectSoundFontControl: SelectSoundFontControl) {
        self.messageQueue = DispatchQueue(label: "MIDIController",
                                          qos: .userInteractive,
                                          attributes: [],
                                          autoreleaseFrequency: .never,
                                          target: DispatchQueue.global(qos: .userInteractive))
        self.keyboard = keyboard
        self.selectSoundFontControl = selectSoundFontControl
    }
}

extension MIDIController: MIDIReceiver {

    public func noteOff(note: UInt8) { keyboard?.noteOff(note: note) }
    public func noteOn(note: UInt8, velocity: UInt8) { keyboard?.noteOn(note: note, velocity: velocity) }
    public func releaseAllKeys() { keyboard?.releaseAllKeys() }
    public func polyphonicKeyPressure(note: UInt8, pressure: UInt8) { keyboard?.polyphonicKeyPressure(note: note, pressure: pressure) }
    public func channelPressure(pressure: UInt8) { keyboard?.channelPressure(pressure: pressure) }
    public func pitchBendChange(value: UInt16) { keyboard?.pitchBendChange(value: value) }

    public func controlChange(controller: UInt8, value: UInt8) {
        switch controller {
        case selectedFontControllerId:
            if value < 64 { selectSoundFontControl.previousFont() }
            if value > 64 { selectSoundFontControl.nextFont() }
        case selectedPresetControllerId:
            if value < 64 { selectSoundFontControl.previousPreset() }
            if value > 64 { selectSoundFontControl.nextPreset() }
        default:
            break
        }
    }

    public func programChange(program: UInt8) {}
}
