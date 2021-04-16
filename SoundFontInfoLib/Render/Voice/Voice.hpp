// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Render/Envelope/Generator.hpp"
#include "Render/LFO.hpp"
#include "Render/Sample/CanonicalBuffer.hpp"
#include "Render/Sample/Generator.hpp"
#include "Render/Voice/State.hpp"

namespace SF2 {
namespace Render {
namespace Voice {

class Setup;

/**
 A voice renders audio samples for a given note / pitch.
 */
class Voice
{
public:

    Voice(double sampleRate, const Setup& setup);

    void keyReleased() {
        amp_.gate(false);
        filter_.gate(false);
    }

    bool isActive() const { return amp_.isActive(); }

    bool canLoop() const {
        return (loopingMode_ == State::continuously || (loopingMode_ == State::duringKeyPress && amp_.isGated()));
    }

    AUValue render() {
        if (!isActive()) return 0.0;

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
        return sampleGenerator_.generate(canLoop()) * gain;
    }

private:
    State state_;
    State::LoopingMode loopingMode_;
    Sample::Generator<AUValue> sampleGenerator_;

    Envelope::Generator amp_;
    Envelope::Generator filter_;

    LFO<AUValue> modulator_;
    LFO<AUValue> vibrator_;
};

} // namespace Voice
} // namespace Render
} // namespace SF2
