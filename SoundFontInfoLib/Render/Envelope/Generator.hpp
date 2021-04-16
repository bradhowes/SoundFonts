// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>

#include <algorithm>
#include <cmath>
#include <limits>

#include "Entity/Generator/Index.hpp"
#include "Render/Utils.hpp"
#include "Render/Envelope/Stage.hpp"
#include "Render/Voice/State.hpp"

namespace SF2 {
namespace Render {
namespace Envelope {

/**
 Collection of states for all of the stages in an envelope.
 */
using Stages = Stage[static_cast<int>(StageIndex::release) + 1];

/**
 Generator of values for the SF2 volume/filter envelopes. An envelope contains 6 stages:

 - Delay -- number of seconds to delay the beginning of the attack stage
 - Attack -- number of seconds to ramp up from 0.0 to 1.0. Also supports non-linear curvature.
 - Hold -- number of seconds to hold the envelope at 1.0 before entering the decay stage.
 - Decay -- number of seconds to lower the envelope from 1.0 to the sustain level
 - Sustain -- a stage that lasts as long as a note is held down
 - Release -- number of seconds to go from sustain level to 0.0

 The envelope will remain in the idle state until `gate(true)` is invoked. It will remain in the sustain stage until
 `gate(false)` is invoked at which point it will enter the `release` stage. Although the stages above are listed in the
 order in which they are performed, any stage will transition to the `release` stage upon a `gate(false)`
 call.

 The more traditional ADSR (attack, decay, sustain, release) envelope can be achieve by setting the delay and hold
 durations to zero (0.0).
 */
class Generator {
public:
    using Index = Entity::Generator::Index;

    inline static constexpr double defaultCurvature = 0.01;

    /**
     Create new envelope definition with a bare configuration.

     @param sampleRate number of samples per second
     */
    explicit Generator(double sampleRate) : Generator(sampleRate, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0) {}

    static Generator Volume(const Voice::State& state) {
        return Generator(state.sampleRate(),
                         state[Index::delayVolumeEnvelope],
                         state[Index::attackVolumeEnvelope],
                         state[Index::holdVolumeEnvelope],
                         state[Index::decayVolumeEnvelope],
                         1.0 - state[Index::sustainVolumeEnvelope],
                         state[Index::releaseVolumeEnvelope],
                         true);
    }

    static Generator Modulator(const Voice::State& state) {
        return Generator(state.sampleRate(),
                         state[Index::delayModulatorEnvelope],
                         state[Index::attackModulatorEnvelope],
                         state[Index::holdModulatorEnvelope],
                         state[Index::decayModulatorEnvelope],
                         1.0 - state[Index::sustainModulatorEnvelope],
                         state[Index::releaseModulatorEnvelope],
                         true);
    }

    /**
     Create new envelope definition.

     @param sampleRate number of samples per second
     @param delay number of seconds before the attack stage begins
     @param attack duration of the attack stage where the envelope ramps from 0.0 to 1.0
     @param hold duration of the hold stage where the envelope remains at 1.0
     @param decay duration of the decay stage where the envelope ramps down from 1.0 to the sustain level
     @param sustain the sustain level (between 0.0 and 1.0)
     @param release duration of the release stage where the envelope ramps down from the sustain level to 0.0
     */
    Generator(double sampleRate, double delay, double attack, double hold, double decay, double sustain,
              double release, bool noteOn = false) :
    stages_{
        Stage::ConfigureDelay(samplesFor(sampleRate, delay)),
        Stage::ConfigureAttack(samplesFor(sampleRate, attack), defaultCurvature),
        Stage::ConfigureHold(samplesFor(sampleRate, hold)),
        Stage::ConfigureDecay(samplesFor(sampleRate, decay), defaultCurvature, sustain),
        Stage::ConfigureSustain(sustain),
        Stage::ConfigureRelease(samplesFor(sampleRate, release), defaultCurvature, sustain)
    }
    {
        if (noteOn) gate(true);
    }

    /**
     Set the status of a note playing. When true, the envelope begins proper. When set to false, the envelope will
     jump to the release stage.
     */
    void gate(bool noteOn) {
        if (noteOn) {
            value_ = 0.0;
            enterStage(StageIndex::delay);
        }
        else if (stageIndex_ != StageIndex::idle) {
            enterStage(StageIndex::release);
        }
    }

    /// @returns the currently active stage.
    StageIndex stage() const { return stageIndex_; }

    /// @returns true if the generator still has values to emit
    bool isActive() const { return stageIndex_ != StageIndex::idle; }

    /// @returns true if the generator is active and has not yet reached the release state
    bool isGated() const { return isActive() && stageIndex_ != StageIndex::release; }

    /// @returns the current envelope value.
    double value() const { return value_; }

    /**
     Calculate the next envelope value. This must be called on every sample for proper timing of the stages.

     @returns the new envelope value.
     */
    double process() {
        switch (stageIndex_) {
            case StageIndex::delay: checkIfEndStage(StageIndex::attack); break;
            case StageIndex::attack: updateValue(); checkIfEndStage(StageIndex::hold); break;
            case StageIndex::hold: checkIfEndStage(StageIndex::decay); break;
            case StageIndex::decay: updateAndCompare(sustainLevel(), StageIndex::sustain); break;
            case StageIndex::release: updateAndCompare(0.0, StageIndex::idle); break;
            default: break;
        }

        return value_;
    }

private:

    static int samplesFor(double sampleRate, double duration) { return round(sampleRate * duration); }

    void updateAndCompare(double floor, StageIndex next) {
        updateValue();
        if (value_ < floor)
            enterStage(next);
        else
            checkIfEndStage(next);
    }

    const Stage& active() const { return stage(stageIndex_); }

    const Stage& stage(StageIndex stageIndex) const { return stages_[static_cast<int>(stageIndex)]; }

    double sustainLevel() const { return stage(StageIndex::sustain).initial_; }

    void updateValue() { value_ = active().next(value_); }

    void checkIfEndStage(StageIndex next) {
        if (--counter_ == 0) {
            os_log_info(log_, "end stage: %{public}s", StageName(stageIndex_));
            enterStage(next);
        }
    }

    int activeDurationInSamples() const { return active().durationInSamples_; }

    void enterStage(StageIndex next) {
        os_log_info(log_, "new stage: %{public}s", StageName(next));
        stageIndex_ = next;
        switch (stageIndex_) {
            case StageIndex::delay:
                if (activeDurationInSamples()) break;
                os_log_info(log_, "next stage: attack");
                stageIndex_ = StageIndex::attack;

            case StageIndex::attack:
                if (activeDurationInSamples()) break;
                os_log_info(log_, "next stage: hold");
                stageIndex_ = StageIndex::hold;

            case StageIndex::hold:
                value_ = 1.0;
                if (activeDurationInSamples()) break;
                os_log_info(log_, "next stage: decay");
                stageIndex_ = StageIndex::decay;

            case StageIndex::decay:
                if (activeDurationInSamples()) break;
                os_log_info(log_, "next stage: sustain");
                stageIndex_ = StageIndex::sustain;

            case StageIndex::sustain:
                value_ = active().initial_;
                break;

            case StageIndex::release:
                if (activeDurationInSamples()) break;
                os_log_info(log_, "next stage: idle");
                stageIndex_ = StageIndex::idle;
                value_ = 0.0;

            case StageIndex::idle: return;
        }

        counter_ = activeDurationInSamples();
    }

    Stages stages_;
    StageIndex stageIndex_{StageIndex::idle};
    int counter_{0};
    double value_{0.0};
    os_log_t log_{os_log_create("SF2", "Generator")};
};

} // namespace Envelope
} // namespace Render
} // namespace SF2
