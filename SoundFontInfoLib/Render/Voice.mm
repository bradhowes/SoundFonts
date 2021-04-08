// Copyright © 2021 Brad Howes. All rights reserved.

#include <cmath>

#include "Render/Voice.hpp"

using namespace SF2::Render;

Voice::Voice(double sampleRate, const SampleBuffer<AUValue>& sampleBuffer, const Note& note, const Envelope& amp)
: sampleRate_{sampleRate}, sampleBuffer_{sampleBuffer}, sampleIndex_{sampleBuffer.header()}, note_{note},
  amp_{amp.generator()}
{
    amp_.gate(true);

    const auto& header = sampleBuffer_.header();
    auto sampleRateRatio = double(header.sampleRate()) / sampleRate_;
    auto frequencyRatio = double(std::pow(2.0, double(note_.value() - header.originalMIDIKey()) / 12.0));
    auto increment = sampleRateRatio * frequencyRatio;

    sampleIndex_.setIncrement(increment);
}
