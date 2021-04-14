// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Render/Envelope/Generator.hpp"
#include "Render/LFO.hpp"
#include "Render/SampleBuffer.hpp"
#include "Render/Voice/VoiceState.hpp"

namespace SF2 {
namespace Render {

class VoiceStateInitializer;

/**
 A voice renders audio samples for a given note / pitch.
 */
class Voice
{
public:
    Voice(double sampleRate, const VoiceStateInitializer& initializer);

    void keyReleased() {
        amp_.gate(false);
        filter_.gate(false);
    }

    bool isActive() const { return amp_.isActive(); }

    bool canLoop() const {
        return (loopingMode_ == VoiceState::continuously ||
                (loopingMode_ == VoiceState::duringKeyPress && amp_.isGated()));
    }

    AUValue render() {
        // if (!isActive()) return 0.0;

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
        return sampleBuffer_.read(sampleIndex_, canLoop()) * gain;
    }

private:
    VoiceState state_;
    VoiceState::LoopingMode loopingMode_;
    SampleBuffer<AUValue> sampleBuffer_;
    SampleIndex sampleIndex_;
    UByte key_;

    Envelope::Generator amp_;
    Envelope::Generator filter_;

    LFO<AUValue> modulator_;
    LFO<AUValue> vibrator_;
};

} // namespace Render
} // namespace SF2
