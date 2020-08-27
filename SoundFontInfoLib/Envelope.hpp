// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <cassert>
#include <cmath>
#include <limits>
#include <vector>

namespace SF2 {

/**
 Representation of a traditional synthesizer volume/filter envelope. This one provides for 6 stages:

 - Delay -- number of seconds to delay the beginning of the attack stage
 - Attack -- number of seconds to ramp up from 0.0 to 1.0. Also supports non-linear curvature.
 - Hold -- number of seconds to hold the envelope at 1.0 before entering the decay stage.
 - Decay -- number of seconds to lower the envelope from 1.0 to the sustain level
 - Sustain -- a stage that lasts as long as a note is held down
 - Release -- number of seconds to go from sustain level to 0.0

 The envelope will remain in the idle state until `gate(true)` is invoked. It will remain in the sustain stage until `gate(false)` is invoked at which point it will enter the
 `release` stage. Althought the stages above are listed in the order in which they are performed, any stage will transition to the `release` stage upon a `gate(false)`
 call.

 The more traditional ADSR (attack, decay, sustain, release) envelope can be achieve by setting the delay and hold durations to zero (0.0).
 */
class Envelope
{
public:

    /**
     The stages that are supported by this envelope system.
     */
    enum struct Stage {
        idle = -1,
        delay = 0,
        attack,
        hold,
        decay,
        sustain,
        release
    };

    /**
     Number of stages being used.
     */
    static constexpr int numStages = static_cast<int>(Stage::release) + 1;
    static constexpr double defaultCurvature = 0.01;
    static constexpr double minimumCurvature = 0.000000001;
    static constexpr double maxiumCurvature = 10.0;

    /**
     Configuration for a stage of the envelope. One configuration can be used to generate many envelopes.
     */
    struct StageConfiguration
    {
        /**
         Obtain the next value of a stage. Requires the last value that was generated (by this stage or the prevous one).
         */
        double next(double last) const { return std::max(std::min(last * alpha + beta, 1.0), 0.0); }

        /**
         Generate a configuration for the attack stage.
         */
        void setAttackRate(double sampleCount, double curvature);

        /**
         Generate a configuration that will emit a constant value for a fixed or indefinite time.
         */
        void setConstant(double sampleCount, double value);

        /**
         Generate a configuration for the decay stage.
         */
        void setDecayRate(double sampleCount, double curvature, double sustainValue);

        /**
         Generate a configuration for the sustain stage.
         */
        void setSustainLevel(double sustainLevel);

        /**
         Generate a configuration for the release stage.
         */
        void setReleaseRate(double sampleCount, double curvature, double sustainValue);

        double initial{0.0};
        double alpha{0.0};
        double beta{0.0};
        uint32_t sampleCount{0};
    };

    using StageConfigs = StageConfiguration[numStages];

    /**
     Manager for a instance of an envelope. Uses a colection of StageConfigurations to set the parameters of the envelope.
     */
    struct Generator {

        /**
         Construct a new envelope generator.
         */
        explicit Generator(StageConfigs const& configs) : configs_{configs} {}

        /**
         Obtain the currently active stage.
         */
        Stage stage() const { return stage_; }

        /**
         Obtain the current envelope value.
         */
        double value() const { return value_; }

        /**
         Set the status of a note playing. When true, the evenlope begins proper. When set to false, the envelope will jump to the release stage.
         */
        void gate(bool noteOn)
        {
            if (noteOn) {
                value_ = 0.0;
                enterStage(Stage::delay);
            }
            else if (stage_ != Stage::idle) {
                enterStage(Stage::release);
            }
        }

        /**
         Calculate the next envelope value. This must be called on every sample for proper timing of the stages.
         */
        double process()
        {
            switch (stage_) {
                case Stage::delay: checkIfEndStage(Stage::attack); break;

                case Stage::attack:
                    updateValue();
                    checkIfEndStage(Stage::hold);
                    break;

                case Stage::hold: checkIfEndStage(Stage::decay); break;

                case Stage::decay:
                    updateValue();
                    if (value_ <= sustainLevel() ) {
                        enterStage(Stage::sustain);
                    }
                    else {
                        checkIfEndStage(Stage::sustain);
                    }
                    break;

                case Stage::sustain: break;

                case Stage::release:
                    updateValue();
                    if (value_ <= 0.0 ) {
                        enterStage(Stage::idle);
                    }
                    else {
                        checkIfEndStage(Stage::idle);
                    }
                    break;

                case Stage::idle: break;
            }

            return value_;
        }

    private:

        int stageAsIndex() const { return static_cast<int>(stage_); }

        StageConfiguration const& active() const { return configs_[stageAsIndex()]; }

        StageConfiguration const& stage(Stage stage) const { return configs_[static_cast<int>(stage)]; }

        double sustainLevel() const { return stage(Stage::sustain).initial; }

        void updateValue() { value_ = active().next(value_); }

        void checkIfEndStage(Stage next) { if (--remainingDuration_ == 0) enterStage(next); }

        /**
         Enter the given stage, setting it up for processing. If the stage has no activity, move to the next one until there is one with non-zero samples or the end of
         the stage sequence is reached.
         */
        void enterStage(Stage next)
        {
            stage_ = next;
            switch (stage_) {
                case Stage::delay:
                    if (active().sampleCount != 0) break;
                    stage_ = Stage::attack;

                case Stage::attack:
                    if (active().sampleCount != 0) break;
                    stage_ = Stage::hold;

                case Stage::hold:
                    value_ = 1.0;
                    if (active().sampleCount != 0) break;
                    stage_ = Stage::decay;

                case Stage::decay:
                    if (active().sampleCount != 0) break;
                    stage_ = Stage::sustain;

                case Stage::sustain:
                    value_ = active().initial;
                    break;

                case Stage::release:
                    if (active().sampleCount != 0) break;
                    stage_ = Stage::idle;
                    value_ = 0.0;

                case Stage::idle: return;
            }

            remainingDuration_ = active().sampleCount;
        }

        StageConfigs const& configs_;
        Stage stage_{Stage::idle};
        double value_{0.0};
        uint32_t remainingDuration_{0};
    };

    /**
     Create new envelope factory.
     */
    Envelope(double sampleRate);

    void setDelay(double duration);

    void setAttackRate(double duration, double curvature = defaultCurvature);

    void setHoldDuration(double duration);

    void setDecayRate(double duration, double curvature = defaultCurvature);

    void setSustainLevel(double sustainLevel);

    void setReleaseRate(double duration, double curvature = defaultCurvature);

    /**
     Create a new envelope generator using the configured envelope settings.
     */
    Generator generator() const { return Generator(configs_); }

private:

    static int stageAsIndex(Stage stage) { return static_cast<int>(stage); }

    StageConfiguration& stage(Stage stage) { return configs_[static_cast<int>(stage)]; }

    static double clampCurvature(double curvature)
    {
        return std::max(std::min(curvature, maxiumCurvature), minimumCurvature);
    }

    static double calculateCoefficient(double rate, double curvature)
    {
        return (rate <= 0.0) ? 0.0 : std::exp(-std::log((1.0 + curvature) / curvature) / rate);
    }

    double samplesFor(double duration) const { return round(sampleRate_ * duration); }

    StageConfiguration configs_[numStages];

    double delayDuration_{0.0};
    double attackDuration_{0.0};
    double attackCurvature_{defaultCurvature};
    double holdDuration_{0.0};
    double decayDuration_{0.0};
    double decayCurvature_{defaultCurvature};
    double sustainLevel_{1.0};
    double releaseDuration_{0.0};
    double releaseCurvature_{defaultCurvature};

    double sampleRate_;
};

}
