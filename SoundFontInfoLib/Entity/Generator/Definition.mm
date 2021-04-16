// Copyright © 2020 Brad Howes. All rights reserved.

#include <cmath>
#include <iostream>

#include "Entity/Generator/Generator.hpp"

using namespace SF2::Entity::Generator;

void
Definition::dump(const Amount& amount) const
{
    double value = convertedValueOf(amount);
    switch (valueKind_) {
        case ValueKind::unsignedShort: std::cout << value; break;
        case ValueKind::offset: std::cout << value << " bytes"; break;
        case ValueKind::coarseOffset: std::cout << value << " bytes"; break;
        case ValueKind::signedShort: std::cout << value; break;
        case ValueKind::signedCents: std::cout << value << " oct"; break;
        case ValueKind::signedCentsBel: std::cout << value << " dB"; break;
        case ValueKind::unsignedPercent: std::cout << value << "%"; break;
        case ValueKind::signedPercent: std::cout << value << "%"; break;
        case ValueKind::signedFrequencyCents: std::cout << value << " Hz"; break;
        case ValueKind::signedTimeCents: std::cout << value << " seconds"; break;
        case ValueKind::signedSemitones: std::cout << value << " notes"; break;

        case ValueKind::range: std::cout << '[' << amount.low() << '-' << amount.high() << ']'; break;
    }

    std::cout << " (" << (isUnsignedValue() ? amount.unsignedAmount() : amount.signedAmount()) << ')';
}


// Allow compile-time check that A is a real Index value and then convert to string.
#define N(A) (Index::A != Index::numValues) ? (# A) : nullptr

std::array<Definition, Definition::NumDefs> const Definition::definitions_{
    Definition(N(startAddressOffset), ValueKind::offset, false),
    Definition(N(endAddressOffset), ValueKind::offset, false),
    Definition(N(startLoopAddressOffset), ValueKind::offset, false),
    Definition(N(endLoopAddressOffset), ValueKind::offset, false),
    Definition(N(startAddressCoarseOffset), ValueKind::coarseOffset, false),
    // 5
    Definition(N(modulatorLFOToPitch), ValueKind::signedCents, true),
    Definition(N(vibratoLFOToPitch), ValueKind::signedCents, true),
    Definition(N(modulatorEnvelopeToPitch), ValueKind::signedCents, true),
    Definition(N(initialFilterCutoff), ValueKind::signedFrequencyCents, true),
    Definition(N(initialFilterResonance), ValueKind::signedCentsBel, true),
    // 10
    Definition(N(modulatorLFOToFilterCutoff), ValueKind::signedShort, true),
    Definition(N(modulatorEnvelopeToFilterCutoff), ValueKind::signedShort, true),
    Definition(N(endAddressCoarseOffset), ValueKind::coarseOffset, false),
    Definition(N(modulatorLFOToVolume), ValueKind::signedCentsBel, true),
    Definition(N(unused1), ValueKind::signedShort, false),
    // 15
    Definition(N(chorusEffectSend), ValueKind::unsignedPercent, true),
    Definition(N(reverbEffectSend), ValueKind::unsignedPercent, true),
    Definition(N(pan), ValueKind::signedPercent, true),
    Definition(N(unused2), ValueKind::unsignedShort, false),
    Definition(N(unused3), ValueKind::unsignedShort, false),
    // 20
    Definition(N(unused4), ValueKind::unsignedShort, false),
    Definition(N(delayModulatorLFO), ValueKind::signedTimeCents, true),
    Definition(N(frequencyModulatorLFO), ValueKind::signedFrequencyCents, true),
    Definition(N(delayVibratoLFO), ValueKind::signedTimeCents, true),
    Definition(N(frequencyVibratoLFO), ValueKind::signedFrequencyCents, true),
    // 25
    Definition(N(delayModulatorEnvelope), ValueKind::signedTimeCents, true),
    Definition(N(attackModulatorEnvelope), ValueKind::signedTimeCents, true),
    Definition(N(holdModulatorEnvelope), ValueKind::signedTimeCents, true),
    Definition(N(decayModulatorEnvelope), ValueKind::signedTimeCents, true),
    Definition(N(sustainModulatorEnvelope), ValueKind::unsignedPercent, true),
    // 30
    Definition(N(releaseModulatorEnvelope), ValueKind::signedTimeCents, true),
    Definition(N(midiKeyModulatorToEnvelopeHold), ValueKind::signedShort, true),
    Definition(N(midiKeyModulatorToEnvelopeDecay), ValueKind::signedShort, true),
    Definition(N(delayVolumeEnvelope), ValueKind::signedTimeCents, true),
    Definition(N(attackVolumeEnvelope), ValueKind::signedTimeCents, true),
    // 35
    Definition(N(holdVolumeEnvelope), ValueKind::signedTimeCents, true),
    Definition(N(decayVolumeEnvelope), ValueKind::signedTimeCents, true),
    Definition(N(sustainVolumeEnvelope), ValueKind::signedCentsBel, true),
    Definition(N(releaseVolumeEnvelope), ValueKind::signedTimeCents, true),
    Definition(N(midiKeyToVolumeEnvelopeHold), ValueKind::signedShort, true),
    // 40
    Definition(N(midiKeyToVolumeEnvelopeDecay), ValueKind::signedShort, true),
    Definition(N(instrument), ValueKind::unsignedShort, true),
    Definition(N(reserved1), ValueKind::signedShort, false),
    Definition(N(keyRange), ValueKind::range, true),
    Definition(N(velocityRange), ValueKind::range, true),
    // 45
    Definition(N(startLoopAddressCoarseOffset), ValueKind::coarseOffset, false),
    Definition(N(forcedMIDIKey), ValueKind::signedShort, false),
    Definition(N(forcedMIDIVelocity), ValueKind::signedShort, false),
    Definition(N(initialAttenuation), ValueKind::signedCentsBel, true),
    Definition(N(reserved2), ValueKind::unsignedShort, false),
    // 50
    Definition(N(endLoopAddressCoarseOffset), ValueKind::coarseOffset, false),
    Definition(N(coarseTune), ValueKind::signedSemitones, true),
    Definition(N(fineTune), ValueKind::signedCents, true),
    Definition(N(sampleID), ValueKind::unsignedShort, false),
    Definition(N(sampleModes), ValueKind::unsignedShort, false),
    // 55
    Definition(N(reserved3), ValueKind::signedShort, false),
    Definition(N(scaleTuning), ValueKind::unsignedShort, true),
    Definition(N(exclusiveClass), ValueKind::unsignedShort, false),
    Definition(N(overridingRootKey), ValueKind::signedShort, false),
    Definition(N(initialPitch), ValueKind::unsignedShort, false),
};
