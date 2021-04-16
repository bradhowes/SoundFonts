// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Envelope/Generator.hpp"

#include "Render/Voice/Setup.hpp"
#include "Render/Voice/State.hpp"

using namespace SF2::Render::Voice;

State::State(double sampleRate, const Setup& setup) :
values_{}, sampleRate_{sampleRate}, key_{setup.key()}, velocity_{setup.velocity()}
{
    values_.fill(0.0);

    setRaw(Index::initialFilterCutoff, 13500);
    setRaw(Index::delayModulatorLFO, -12000);
    setRaw(Index::delayVibratoLFO, -12000);
    setRaw(Index::delayModulatorEnvelope, -12000);
    setRaw(Index::attackModulatorEnvelope, -12000);
    setRaw(Index::holdModulatorEnvelope, -12000);
    setRaw(Index::decayModulatorEnvelope, -12000);
    setRaw(Index::releaseModulatorEnvelope, -12000);
    setRaw(Index::delayVolumeEnvelope, -12000);
    setRaw(Index::attackVolumeEnvelope, -12000);
    setRaw(Index::holdVolumeEnvelope, -12000);
    setRaw(Index::decayVolumeEnvelope, -12000);
    setRaw(Index::releaseVolumeEnvelope, -12000);
    setRaw(Index::forcedMIDIKey, -1);
    setRaw(Index::forcedMIDIVelocity, -1);
    setRaw(Index::scaleTuning, 100);
    setRaw(Index::overridingRootKey, -1);

    setup.apply(*this);
}
