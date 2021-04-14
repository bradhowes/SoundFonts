// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Voice/VoiceState.hpp"
#include "Render/Voice/VoiceStateInitializer.hpp"

using namespace SF2::Render;
VoiceState::VoiceState(double sampleRate, const VoiceStateInitializer& initializer) :
sampleRate_{sampleRate}, values_{} {
    setDefaults();
    initializer.apply(*this);
}
