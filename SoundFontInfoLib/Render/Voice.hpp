// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Render/Envelope.hpp"
#include "Render/Note.hpp"
#include "Render/SampleBuffer.hpp"

namespace SF2 {
namespace Render {

class Voice
{
public:
    Voice(double sampleRate, const SampleBuffer<AUValue>& sampleBuffer, const Note& note, const Envelope& amp);

    void keyReleased() { amp_.gate(false); }

    AUValue render() {
        auto gain = amp_.process();
        auto sample = sampleBuffer_.read(sampleIndex_, amp_.isGated());
        return sample * gain;
    }

private:
    double sampleRate_;
    SampleBuffer<AUValue> sampleBuffer_;
    SampleIndex sampleIndex_;
    Note note_;
    Envelope::Generator amp_;
};

} // namespace Render
} // namespace SF2
