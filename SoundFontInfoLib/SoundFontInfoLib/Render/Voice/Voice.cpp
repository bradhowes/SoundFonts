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

Voice::Voice(Float sampleRate, const Channel& channel, size_t voiceIndex) :
state_{sampleRate, channel},
loopingMode_{State::none},
sampleGenerator_{state_, Render::Sample::Generator::Interpolator::linear},
gainEnvelope_{},
modulatorEnvelope_{},
modulatorLFO_{},
vibratoLFO_{},
voiceIndex_{voiceIndex}
{
  ;
}

void
Voice::configure(const Config& config, Engine::Tick startTick)
{
  startedTick_ = startTick;
  state_.prepareForVoice(config);
  loopingMode_ = state_.loopingMode();
  gainEnvelope_ = Envelope::Generator::forVol(state_);
  modulatorEnvelope_ = Envelope::Generator::forMod(state_);
  sampleGenerator_.configure(config.sampleSource());
  modulatorLFO_ = LFO::forModulator(state_);
  vibratoLFO_ = LFO::forVibrato(state_);
}
