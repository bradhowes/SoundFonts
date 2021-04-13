// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cassert>

#include "Entity/Generator/Amount.hpp"
#include "Entity/Generator/Index.hpp"

namespace SF2 {
namespace Render {

/**
 Generator state values for a rendering voice. These are values from generators. There is the initial state which is
 the default values (see `setDefaults`). Next, there are instrument generators from the zones that match the MIDI
 key/velocity values of a MIDI event. These can override any default values. Finally, there are the preset generators
 which refine any values by adding to them. Note that not all generators are available for refining. Those that are
 return true from `Generator::Definition::isAvailableInPreset`.
 */
class VoiceState
{
public:
    using Amount = Entity::Generator::Amount;
    using Index = Entity::Generator::Index;

    /**
     Create new state vector with a default 44100.0 sample rate.
     */
    VoiceState() : VoiceState(44100.0) {}

    /**
     Create new state vector with a given sample rate.

     @param sampleRate the sample rate of audio being rendered
     */
    explicit VoiceState(double sampleRate) : sampleRate_{sampleRate}, values_{} { setDefaults(); }

    /**
     Obtain a specific generator value.

     @param index the index of the generator
     @returns current value of the generator
     */
    double operator[](Index index) const { return values_[Entity::Generator::indexValue(index)]; }

    double& operator[](Index index) { return values_[Entity::Generator::indexValue(index)]; }

    double sampleRate() const { return sampleRate_; }

private:

    void setDefaults() {
        using namespace Entity::Generator;
        (*this)[Index::initialFilterCutoff] = 13500;
        (*this)[Index::delayModulatorLFO] = -12000;
        (*this)[Index::delayVibratoLFO] = -12000;
        (*this)[Index::delayModulatorEnvelope] = -12000;
        (*this)[Index::attackModulatorEnvelope] = -12000;
        (*this)[Index::holdModulatorEnvelope] = -12000;
        (*this)[Index::decayModulatorEnvelope] = -12000;
        (*this)[Index::releaseModulatorEnvelope] = -12000;
        (*this)[Index::delayVolumeEnvelope] = -12000;
        (*this)[Index::attackVolumeEnvelope] = -12000;
        (*this)[Index::holdVolumeEnvelope] = -12000;
        (*this)[Index::decayVolumeEnvelope] = -12000;
        (*this)[Index::releaseVolumeEnvelope] = -12000;
        (*this)[Index::midiKey] = -1;
        (*this)[Index::midiVelocity] = -1;
        (*this)[Index::scaleTuning] = 100;
        (*this)[Index::overridingRootKey] = -1;
    }

    double sampleRate_;
    std::array<double, static_cast<size_t>(Entity::Generator::Index::numValues)> values_;
};

} // namespace Render
} // namespace SF2
