// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Render/Envelope.hpp"
#include "Render/LFO.hpp"
#include "Render/Note.hpp"
#include "Render/SampleBuffer.hpp"

namespace SF2 {
namespace Render {

class Voice
{
public:
    Voice(double sampleRate, const SampleBuffer<AUValue>& sampleBuffer, const Note& note,
          const Envelope::Config<AUValue>& amp, const Envelope::Config<AUValue>& filter);

    void keyReleased() { amp_.gate(false); }

    AUValue render() {
        //
        // Steps:
        // 1. Check for voice completion
        // 2. Update amp/mod envelopes
        // 3. Update modulation/vibrato LFOs
        // 4. Calculate phase
        // 5. Generate samples
        // 6. Filter samples
        //
        auto gain = amp_.process();
        auto sample = sampleBuffer_.read(sampleIndex_, amp_.isGated());
        return sample * gain;
    }

private:
    double sampleRate_;
    SampleBuffer<AUValue> sampleBuffer_;
    SampleIndex sampleIndex_;
    Note note_;

    Envelope::Generator<AUValue> amp_;
    Envelope::Generator<AUValue> filter_;

    LFO<AUValue> modulator_;
    LFO<AUValue> vibrator_;
};

} // namespace Render
} // namespace SF2
