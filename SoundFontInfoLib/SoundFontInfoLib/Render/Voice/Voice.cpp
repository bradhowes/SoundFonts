// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "MIDI/Channel.hpp"
#include "Render/Envelope/Generator.hpp"
#include "Render/Voice/Config.hpp"
#include "Render/Voice/Voice.hpp"

using namespace SF2::MIDI;
using namespace SF2::Render::Voice;
using namespace SF2::Entity::Generator;

Voice::Voice(double sampleRate, const Channel& channel, const Config& config) :
state_{sampleRate, channel, config},
loopingMode_{state_.loopingMode()},
sampleGenerator_{config.sampleBuffer(), state_},
gainEnvelope_{Envelope::Generator::Volume(state_)},
modulatorEnvelope_{Envelope::Generator::Modulator(state_)},
modulatorLFO_{
  LFO::Config(sampleRate)
  .frequency(state_.modulated(Index::frequencyModulatorLFO))
  .delay(state_.modulated(Index::delayModulatorLFO))
  .make()
},
vibratoLFO_{
  LFO::Config(sampleRate)
  .frequency(state_.modulated(Index::frequencyVibratoLFO))
  .delay(state_.modulated(Index::delayVibratoLFO))
  .make()
}
{
  os_log_debug(log_, "loopingMode: %d", loopingMode_);
}
