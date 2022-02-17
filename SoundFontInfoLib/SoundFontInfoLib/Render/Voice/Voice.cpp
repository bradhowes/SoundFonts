// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "MIDI/Channel.hpp"
#include "Render/Config.hpp"
#include "Render/Envelope/Generator.hpp"
#include "Render/Sample/Bounds.hpp"
#include "Render/Voice/Voice.hpp"

using namespace SF2::MIDI;
using namespace SF2::Render::Voice;
using namespace SF2::Entity::Generator;

Voice::Voice(double sampleRate, const Channel& channel, size_t voiceIndex) :
state_{sampleRate, channel},
loopingMode_{State::none},
sampleGenerator_{state_, Render::Sample::Generator::Interpolator::linear},
gainEnvelope_{},
modulatorEnvelope_{},
modulatorLFO_{LFO::Config{sampleRate}},
vibratoLFO_{LFO::Config{sampleRate}},
voiceIndex_{voiceIndex}
{
  ;
}

void
Voice::configure(const Config& config, Engine::Tick startTick)
{
  startedTick_ = startTick;

  state_.configure(config);
  loopingMode_ = state_.loopingMode();

  gainEnvelope_ = Envelope::Generator::Volume(state_);
  modulatorEnvelope_ = Envelope::Generator::Modulator(state_);

//  sampleGenerator_{Sample::Generator(sampleRate, config.sampleBuffer(),
//                                   Sample::Bounds::make(config.sampleBuffer().header(), state_))},

  modulatorLFO_ = LFO::Config(state_.sampleRate())
    .frequency(state_.modulated(Index::frequencyModulatorLFO))
    .delay(state_.modulated(Index::delayModulatorLFO))
    .make();

  vibratoLFO_ = LFO::Config(state_.sampleRate())
    .frequency(state_.modulated(Index::frequencyVibratoLFO))
    .delay(state_.modulated(Index::delayVibratoLFO))
    .make();
}
