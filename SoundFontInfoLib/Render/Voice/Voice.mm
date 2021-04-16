// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Envelope/Generator.hpp"

#include "Render/Voice/Setup.hpp"
#include "Render/Voice/Voice.hpp"

using namespace SF2::Render::Voice;

Voice::Voice(double sampleRate, const Setup& setup) :
state_{sampleRate, setup.key(), setup.velocity()},
loopingMode_{state_.loopingMode()},
sampleGenerator_{setup.sampleBuffer(), state_},
amp_{Envelope::Generator::Volume(state_)},
filter_{Envelope::Generator::Modulator(state_)}
{
    ;
}
