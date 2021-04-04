// Copyright © 2020 Brad Howes. All rights reserved.

#include <limits>

#include "Envelope.hpp"

using namespace SF2;
using namespace SF2::Render;

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

Float
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
            if (active().durationInSamples_) break;
            stage_ = Stage::attack;

        case Stage::attack:
            if (active().durationInSamples_) break;
            stage_ = Stage::hold;

        case Stage::hold:
            value_ = 1.0;
            if (active().durationInSamples_) break;
            stage_ = Stage::decay;

        case Stage::decay:
            if (active().durationInSamples_) break;
            stage_ = Stage::sustain;

        case Stage::sustain:
            value_ = active().initial_;
            break;

        case Stage::release:
            if (active().durationInSamples_) break;
            stage_ = Stage::idle;
            value_ = 0.0;

        case Stage::idle: return;
    }

    counter_ = active().durationInSamples_;
}

void
Envelope::StageConfiguration::configureAttack(int sampleCount, Float curvature)
{
    curvature = clampCurvature(curvature);
    initial_ = 0.0;
    alpha_ = calculateCoefficient(sampleCount, curvature);
    beta_ = (1.0 + curvature) * (1.0 - alpha_);
    durationInSamples_ = sampleCount;
}

void
Envelope::StageConfiguration::setConstant(int sampleCount, Float value)
{
    initial_ = value;
    alpha_ = 1.0;
    beta_ = 0.0;
    durationInSamples_ = sampleCount;
}

void
Envelope::StageConfiguration::configureDecay(int sampleCount, Float curvature, Float sustainLevel)
{
    curvature = clampCurvature(curvature);
    initial_ = 1.0;
    alpha_ = calculateCoefficient(sampleCount, curvature);
    beta_ = (sustainLevel - curvature) * (1.0 - alpha_);
    durationInSamples_ = sampleCount;
}

void
Envelope::StageConfiguration::configureSustain(double level)
{
    initial_ = level;
    alpha_ = 1.0;
    beta_ = 0.0;
    durationInSamples_ = std::numeric_limits<uint16_t>::max();
}

void
Envelope::StageConfiguration::configureRelease(int sampleCount, Float curvature, Float sustainLevel)
{
    initial_ = sustainLevel;
    alpha_ = calculateCoefficient(sampleCount, curvature);
    beta_ = (0.0 - curvature) * (1.0 - alpha_);
    durationInSamples_ = sampleCount;
}

Envelope::Envelope(double sampleRate, const Config& config) : sampleRate_{sampleRate}
{
    stage(Stage::delay).setConstant(samplesFor(config.delay_), 0.0);
    stage(Stage::attack).configureAttack(samplesFor(config.attack_), defaultCurvature);
    stage(Stage::hold).setConstant(samplesFor(config.hold_), 1.0);
    stage(Stage::decay).configureDecay(samplesFor(config.decay_), defaultCurvature, config.sustain_);
    stage(Stage::sustain).configureSustain(config.sustain_);
    stage(Stage::release).configureRelease(samplesFor(config.release_), defaultCurvature, config.sustain_);
}
