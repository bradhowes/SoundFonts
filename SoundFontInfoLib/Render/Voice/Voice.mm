// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Envelope/Generator.hpp"

#include "Render/Voice/Setup.hpp"
#include "Render/Voice/Voice.hpp"

using namespace SF2::Render::Voice;
using namespace SF2::Entity::Generator;

Voice::Voice(double sampleRate, const Setup& setup) :
state_{sampleRate, setup},
loopingMode_{state_.loopingMode()},
sampleGenerator_{setup.sampleBuffer(), state_},
gainEnvelope_{Envelope::Generator::Volume(state_)},
modulatorEnvelope_{Envelope::Generator::Modulator(state_)},
modulatorLFO_{
    LFO<double>::Config(sampleRate)
    .frequency(state_[Index::frequencyModulatorLFO])
    .delay(state_[Index::delayModulatorLFO])
    .make()
},
vibratoLFO_{
    LFO<double>::Config(sampleRate)
    .frequency(state_[Index::frequencyVibratoLFO])
    .delay(state_[Index::delayVibratoLFO])
    .make()
}
{
    os_log_debug(log_, "loopingMode: %d", loopingMode_);
}
