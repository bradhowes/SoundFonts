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
amp_{Envelope::Generator::Volume(state_)},
filter_{Envelope::Generator::Modulator(state_)},
modulator_{sampleRate, state_[Index::frequencyModulatorLFO], state_[Index::delayModulatorLFO]},
vibrator_{sampleRate, state_[Index::frequencyVibratoLFO], state_[Index::delayVibratoLFO]}
{
    os_log_debug(log_, "loopingMode: %d", loopingMode_);
}
