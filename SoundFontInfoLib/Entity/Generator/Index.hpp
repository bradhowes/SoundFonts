// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

namespace SF2 {
namespace Entity {
namespace Generator {

/**
 Enumeration of valid SF2 generators.
 */
enum struct Index : uint16_t {
    startAddressOffset = 0,
    endAddressOffset,
    startLoopAddressOffset,
    endLoopAddressOffset,
    startAddressCoarseOffset,
    // 5
    modulatorLFOToPitch,
    vibratoLFOToPitch,
    modulatorEnvelopeToPitch,
    initialFilterCutoff,
    initialFilterResonance,
    // 10
    modulatorLFOToFilterCutoff,
    modulatorEnvelopeToFilterCutoff,
    endAddressCoarseOffset,
    modulatorLFOToVolume,
    unused1,
    // 15
    chorusEffectSend,
    reverbEffectSend,
    pan,
    unused2,
    unused3,
    // 20
    unused4,
    delayModulatorLFO,
    frequencyModulatorLFO,
    delayVibratoLFO,
    frequencyVibratoLFO,
    // 25
    delayModulatorEnvelope,
    attackModulatorEnvelope,
    holdModulatorEnvelope,
    decayModulatorEnvelope,
    sustainModulatorEnvelope,
    // 30
    releaseModulatorEnvelope,
    midiKeyModulatorToEnvelopeHold,
    midiKeyModulatorToEnvelopeDecay,
    delayVolumeEnvelope,
    attackVolumeEnvelope,
    // 35
    holdVolumeEnvelope,
    decayVolumeEnvelope,
    sustainVolumeEnvelope,
    releaseVolumeEnvelope,
    midiKeyToVolumeEnvelopeHold,
    // 40
    midiKeyToVolumeEnvelopeDecay,
    instrument,
    reserved1,
    keyRange,
    velocityRange,
    // 45
    startLoopAddressCoarseOffset,
    midiKey,
    velocity,
    initialAttenuation,
    reserved2,
    // 50
    endLoopAddressCoarseOffset,
    coarseTune,
    fineTune,
    sampleID,
    sampleMode,
    // 55
    reserved3,
    scaleTuning,
    exclusiveClass,
    overridingRootKey,

    // NOTE: following do not exist in the spec, but are defined here to keep things simple and support the defined
    // modulator presets.
    initialPitch,

    numValues
};

/**
 Representation of the 2-byte generator index found in SF2 files. Provides conversion from raw value to the nicer
 enumerated type.
 */
class RawIndex {
public:

    RawIndex() : value_{0} {}

    /**
     Obtain the raw index value.
     */
    uint16_t value() const { return value_; }

    /**
     Obtain the Index value that corresponds to a raw index value.
     */
    Index index() const { return Index(value_); }

private:
    uint16_t const value_;
};

}
}
}
