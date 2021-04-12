// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>

#include "Types.hpp"

namespace SF2 {
namespace Render {

struct MIDI {

    inline constexpr static UByte MinNote = 0;
    inline constexpr static UByte MaxNote = 127;

    template <typename T>
    static T keyToFrequency(UByte key) {
        return standardNoteFrequencies_[std::clamp(key, MinNote, MaxNote)];
    }

    // #define MAX_NUMBER_OF_TRACKS 128

    enum struct CoreEvent {
        noteOff = 0x80,
        noteOn = 0x90,
        keyPressure = 0xa0,
        controlChange = 0xb0,
        programChange = 0xc0,
        channelPressure = 0xd0,
        pitchBend = 0xe0,
    };

    enum struct ControlChange {
        bankSelectMSB = 0x00,
        modulationWheelMSB = 0x01,
        breathMSB = 0x02,
        footMSB = 0x04,
        portamentoTimeMSB = 0x05,
        dataEntryMSB = 0x06,
        volumeMSB = 0x07,
        balanceMSB = 0x08,
        panMSB = 0x0A,
        expressionMSB = 0x0B,
        effects1MSB = 0x0C,
        effects2MSB = 0x0D,

        generalPurpose1MSB = 0x10,
        generalPurpose2MSB = 0x11,
        generalPurpose3MSB = 0x12,
        generalPurpose4MSB = 0x13,

        bankSelectLSB = 0x20,
        modulationWheelLSB = 0x21,
        breathLSB = 0x22,
        footLSB = 0x24,
        portamentoTimeLSB = 0x25,
        dataEntryLSB = 0x26,
        volumeLSB = 0x27,
        balanceLSB = 0x28,
        panLSB = 0x2A,
        expressionLSB = 0x2B,
        effects1LSB = 0x2C,
        effects2LSB = 0x2D,

        generalPurpose1LSB = 0x30,
        generalPurpose2LSB = 0x31,
        generalPurpose3LSB = 0x32,
        generalPurpose4LSB = 0x33,

        sustainSwitch = 0x40,
        portamentoSwitch = 0x41,
        sostenutoSwitch = 0x42,
        softPedalSwitch = 0x43,
        legatoSwitch = 0x44,
        hold2Switch = 0x45,

        soundControl1 = 0x46,
        soundControl2 = 0x47,
        soundControl3 = 0x48,
        soundControl4 = 0x49,
        soundControl5 = 0x4A,
        soundControl6 = 0x4B,
        soundControl7 = 0x4C,
        soundControl8 = 0x4D,
        soundControl9 = 0x4E,
        soundControl10 = 0x4F,

        generalPurpose5 = 0x50,
        generalPurpose6 = 0x51,
        generalPurpose7 = 0x52,
        generalPurpose8 = 0x53,

        portamentoControl = 0x54,
        effectsDepth1 = 0x5B,
        effectsDepth2 = 0x5C,
        effectsDepth3 = 0x5D,
        effectsDepth4 = 0x5E,
        effectsDepth5 = 0x5F,

        dataEntryIncrement = 0x60,
        dataEntryDecrement = 0x61,

        nprnLSB = 0x62,
        nprnMSB = 0x63,
        rpnLSB = 0x64,
        rpnMSB = 0x65,

        allSoundOff = 0x78,
        allControlOff = 0x79,
        localControl = 0x7A,
        allNotesOff = 0x7B,
        omniOff = 0x7C,
        omniOn = 0x7D,
        polyOff = 0x7E,
        polyOn = 0x7F
    };

    /* General MIDI RPN event numbers (LSB, MSB = 0) */
    enum struct RPNEvent
    {
        pitchBendRange = 0x00,
        channelFineTune = 0x01,
        channelCoarseTune = 0x02,
        tuningProgramChange = 0x03,
        tuningBankSelect = 0x04,
        modulationDepthRange = 0x05
    };

    static std::array<double, MaxNote + 1> standardNoteFrequencies_;
};

} // namespace Render
} // namespace SF2
