// Copyright © 2020 Brad Howes. All rights reserved.

#include <limits>

#include "Envelope.hpp"

using namespace SF2;

constexpr double Envelope::defaultCurvature;
constexpr double Envelope::minimumCurvature;
constexpr double Envelope::maxiumCurvature;

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

