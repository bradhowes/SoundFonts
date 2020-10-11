// Copyright © 2020 Brad Howes. All rights reserved.

#include <limits>

#include "Envelope.hpp"

using namespace SF2::Render;

constexpr double Envelope::defaultCurvature;
constexpr double Envelope::minimumCurvature;
constexpr double Envelope::maxiumCurvature;

void
Envelope::Generator::gate(bool noteOn)
{
    if (noteOn) {
        value_ = 0.0;
        enterStage(Stage::delay);
    }
    else if (stage_ != Stage::idle) {
        enterStage(Stage::release);
    }
}

double
Envelope::Generator::process()
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

void
Envelope::Generator::enterStage(Stage next)
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


void
Envelope::StageConfiguration::setAttackRate(double duration, double curvature)
{
    curvature = clampCurvature(curvature);
    initial = 0.0;
    alpha = calculateCoefficient(duration, curvature);
    beta = (1.0 + curvature) * (1.0 - alpha);
    sampleCount = duration;
}

void
Envelope::StageConfiguration::setConstant(double duration, double value)
{
    initial = value;
    alpha = 1.0;
    beta = 0.0;
    sampleCount = duration;
}

void
Envelope::StageConfiguration::setDecayRate(double duration, double curvature, double sustainLevel)
{
    curvature = clampCurvature(curvature);
    initial = 1.0;
    alpha = calculateCoefficient(duration, curvature);
    beta = (sustainLevel - curvature) * (1.0 - alpha);
    this->sampleCount = duration;
}

void
Envelope::StageConfiguration::setSustainLevel(double sustainLevel)
{
    initial = sustainLevel;
    alpha = 1.0;
    beta = 0.0;
    sampleCount = std::numeric_limits<uint32_t>::max();
}

void
Envelope::StageConfiguration::setReleaseRate(double duration, double curvature, double sustainLevel)
{
    curvature = clampCurvature(curvature);
    alpha = calculateCoefficient(duration, curvature);
    beta = (0.0 - curvature) * (1.0 - alpha);
    sampleCount = duration;
}

Envelope::Envelope(double sampleRate) : sampleRate_{sampleRate}
{
    setSustainLevel(1.0);
}

void
Envelope::setDelay(double duration)
{
    delayDuration_ = duration;
    stage(Stage::delay).setConstant(samplesFor(duration), 0.0);
}

void
Envelope::setAttackRate(double duration, double curvature)
{
    attackDuration_ = duration;
    attackCurvature_ = curvature;
    stage(Stage::attack).setAttackRate(samplesFor(duration), curvature);
}

void
Envelope::setHoldDuration(double duration)
{
    holdDuration_ = duration;
    stage(Stage::hold).setConstant(samplesFor(duration), 1.0);
}

void
Envelope::setDecayRate(double duration, double curvature)
{
    decayDuration_ = duration;
    decayCurvature_ = curvature;
    stage(Stage::decay).setDecayRate(samplesFor(duration), curvature, sustainLevel_);
}

void
Envelope::setSustainLevel(double sustainLevel)
{
    sustainLevel_ = sustainLevel;
    stage(Stage::decay).setDecayRate(samplesFor(decayDuration_), decayCurvature_, sustainLevel_);
    stage(Stage::sustain).setSustainLevel(sustainLevel);
    stage(Stage::release).setReleaseRate(samplesFor(releaseDuration_), releaseCurvature_, sustainLevel_);
}

void
Envelope::setReleaseRate(double duration, double curvature)
{
    releaseDuration_ = duration;
    releaseCurvature_ = curvature;
    stage(Stage::release).setReleaseRate(samplesFor(duration), curvature, sustainLevel_);
}

