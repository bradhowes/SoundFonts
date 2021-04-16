// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Envelope/Generator.hpp"

#include "Render/Voice/Setup.hpp"
#include "Render/Voice/State.hpp"

using namespace SF2::Render::Voice;

State::State(double sampleRate, const Setup& setup) :
values_{}, sampleRate_{sampleRate}, key_{setup.key()}, velocity_{setup.velocity()}
{
    setDefaults();
    setup.apply(*this);
}
