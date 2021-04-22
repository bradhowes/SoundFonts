// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Logger.hpp"
#include "Render/Envelope/Generator.hpp"
#include "Render/LFO.hpp"
#include "Render/Modulator.hpp"
#include "Render/Sample/CanonicalBuffer.hpp"
#include "Render/Sample/Generator.hpp"
#include "Render/Voice/State.hpp"

namespace SF2 {
namespace Render {

namespace MIDI { class Channel; }

namespace Voice {

class Setup;

/**
 A voice renders audio samples for a given note / pitch.
 */
class Voice
{
public:

    Voice(double sampleRate, const MIDI::Channel& channel, const Setup& setup);

    void keyReleased() {
        gainEnvelope_.gate(false);
        modulatorEnvelope_.gate(false);
    }

    bool isActive() const { return gainEnvelope_.isActive(); }

    bool canLoop() const {
        return (loopingMode_ == State::continuously ||
                (loopingMode_ == State::duringKeyPress && gainEnvelope_.isGated()));
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
        auto amplitudeGain = gainEnvelope_.process();
        auto modulatorGain = modulatorEnvelope_.process();

        auto lfoValue = modulatorLFO_.valueAndIncrement();
        auto vibratoValue = vibratoLFO_.valueAndIncrement();

        auto pitchAdjustment = (modulatorGain * state_.modulated(Entity::Generator::Index::modulatorEnvelopeToPitch) +
                                lfoValue * state_.modulated(Entity::Generator::Index::modulatorLFOToPitch) +
                                vibratoValue * state_.modulated(Entity::Generator::Index::vibratoLFOToPitch));

        return sampleGenerator_.generate(pitchAdjustment, canLoop()) * amplitudeGain;
    }

private:
    State state_;
    State::LoopingMode loopingMode_;
    Sample::Generator<AUValue> sampleGenerator_;

    Envelope::Generator gainEnvelope_;
    Envelope::Generator modulatorEnvelope_;

    LFO<double> modulatorLFO_;
    LFO<double> vibratoLFO_;

    inline static Logger log_{Logger::Make("Render", "Voice")};
};

} // namespace Voice
} // namespace Render
} // namespace SF2
