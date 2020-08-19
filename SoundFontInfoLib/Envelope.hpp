// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <algorithm>
#include <cassert>
#include <cmath>
#include <limits>
#include <vector>

namespace SF2 {

class Envelope
{
private:

public:

    struct SegmentConfiguration
    {
        double next(double last) const { return std::max(std::min(last * alpha + beta, 1.0), 0.0); }

        void setAttackRate(double sampleCount, double curvature);
        void setConstant(double sampleCount, double value);
        void setDecayRate(double sampleCount, double curvature, double sustainValue);
        void setSustainLevel(double sustainLevel);
        void setReleaseRate(double sampleCount, double curvature, double sustainValue);

        bool isConstant() const { return alpha == 1.0 && beta == 0.0; }

        double initial{0.0};
        double alpha{0.0};
        double beta{0.0};
        uint32_t sampleCount{0};
    };

    static constexpr double defaultCurvature = 0.01;
    static constexpr double minimumCurvature = 0.000000001;
    static constexpr double maxiumCurvature = 1000.0;

    enum struct Stage {
        idle = -1,
        delay = 0,
        attack,
        hold,
        decay,
        sustain,
        release
    };

    static constexpr int numStages = static_cast<int>(Stage::release) + 1;

    using SegmentConfigs = SegmentConfiguration[numStages];

    struct Generator {

        Generator(SegmentConfigs const& configs) : configs_{configs} {}

        Stage stage() const { return stage_; }

        double value() const { return value_; }

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

        constexpr int stageAsIndex() const { return static_cast<int>(stage_); }
        SegmentConfiguration const& active() const { return configs_[stageAsIndex()]; }
        SegmentConfiguration const& segment(Stage stage) const { return configs_[static_cast<int>(stage)]; }
        double sustainLevel() const { return segment(Stage::sustain).initial; }

        void updateValue() { value_ = active().next(value_); }

        void checkIfEndStage(Stage next) { if (--remainingDuration_ == 0) enterStage(next); }

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

        SegmentConfigs const& configs_;
        Stage stage_{Stage::idle};
        double value_{0.0};
        uint32_t remainingDuration_{0};
    };

    Envelope(double sampleRate);

    void setDelay(double duration);

    void setAttackRate(double duration, double curvature = defaultCurvature);

    void setHoldDuration(double duration);

    void setDecayRate(double duration, double curvature = defaultCurvature);

    void setSustainLevel(double sustainLevel);

    void setReleaseRate(double duration, double curvature = defaultCurvature);

    Generator generator() const { return Generator(segments_); }

private:

    constexpr static int stageAsIndex(Stage stage) { return static_cast<int>(stage); }

    SegmentConfiguration& segment(Stage stage) { return segments_[static_cast<int>(stage)]; }

    static double clampCurvature(double curvature)
    {
        return std::max(std::min(curvature, maxiumCurvature), minimumCurvature);
    }

    static double calculateCoefficient(double rate, double curvature)
    {
        return (rate <= 0.0) ? 0.0 : std::exp(-std::log((1.0 + curvature) / curvature) / rate);
    }

    double samplesFor(double duration) const { return round(sampleRate_ * duration); }

    SegmentConfiguration segments_[numStages];

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
