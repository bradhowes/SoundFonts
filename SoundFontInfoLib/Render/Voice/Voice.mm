// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Envelope/Generator.hpp"
#include "Render/Voice/Voice.hpp"
#include "Render/Voice/VoiceStateInitializer.hpp"

using namespace SF2::Render;

Voice::Voice(double sampleRate, const VoiceStateInitializer& initializer) :
state_{sampleRate, initializer},
loopingMode_{state_.loopingMode()},
sampleBuffer_{initializer.sampleBuffer()},
sampleIndex_{sampleBuffer_.header()},
key_{initializer.key()},
amp_{Envelope::Generator::Volume(state_)},
filter_{Envelope::Generator::Modulator(state_)}
{
    sampleBuffer_.load();
    const auto& header = sampleBuffer_.header();
    auto sampleRateRatio = double(header.sampleRate()) / state_.sampleRate();
    auto frequencyRatio = double(std::pow(2.0, double(key_ - header.originalMIDIKey()) / 12.0));
    auto increment = sampleRateRatio * frequencyRatio;
    sampleIndex_.setIncrement(increment);
}
