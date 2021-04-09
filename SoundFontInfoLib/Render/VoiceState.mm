// Copyright © 2020 Brad Howes. All rights reserved.

#include "VoiceState.hpp"

using namespace SF2;

void Render::VoiceState::setDefaults()
{
    using namespace Entity::Generator;
    setAmount(Index::initialFilterCutoff, 13500);
    setAmount(Index::delayModulatorLFO, -12000);
    setAmount(Index::delayVibratoLFO, -12000);
    setAmount(Index::delayModulatorEnvelope, -12000);
    setAmount(Index::attackModulatorEnvelope, -12000);
    setAmount(Index::holdModulatorEnvelope, -12000);
    setAmount(Index::decayModulatorEnvelope, -12000);
    setAmount(Index::releaseModulatorEnvelope, -12000);
    setAmount(Index::delayVolumeEnvelope, -12000);
    setAmount(Index::attackVolumeEnvelope, -12000);
    setAmount(Index::holdVolumeEnvelope, -12000);
    setAmount(Index::decayVolumeEnvelope, -12000);
    setAmount(Index::sustainVolumeEnvelope, -12000);
    setAmount(Index::releaseVolumeEnvelope, -12000);
    setAmount(Index::midiKey, -1);
    setAmount(Index::velocity, -1);
    setAmount(Index::scaleTuning, 100);
    setAmount(Index::overridingRootKey, -1);
}
