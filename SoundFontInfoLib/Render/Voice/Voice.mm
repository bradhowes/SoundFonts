// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Envelope/Generator.hpp"

#include "Render/Voice/Setup.hpp"
#include "Render/Voice/Voice.hpp"

using namespace SF2::Render::Voice;

Voice::Voice(double sampleRate, const Setup& setup) :
state_{sampleRate, setup},
loopingMode_{state_.loopingMode()},
sampleGenerator_{setup.sampleBuffer(), state_},
amp_{Envelope::Generator::Volume(state_)},
filter_{Envelope::Generator::Modulator(state_)}
{
//    std::cout << "-- loopingMode: " << loopingMode_ << " state_.loopingMode: " << state_.loopingMode()
//    << " state: " << state_[Entity::Generator::Index::sampleModes]
//    << std::endl;
}
