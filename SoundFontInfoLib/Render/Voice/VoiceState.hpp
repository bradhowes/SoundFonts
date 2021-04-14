// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cassert>

#include "Entity/Generator/Generator.hpp"

namespace SF2 {
namespace Render {

class VoiceStateInitializer;

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
    using Definition = Entity::Generator::Definition;

    // These are values for the sampleModes (#54) generator.
    enum LoopingMode {
        none = 0,
        continuously = 1,
        duringKeyPress = 3
    };

    LoopingMode loopingMode() const {
        switch (int((*this)[Index::sampleModes])) {
            case 1: return LoopingMode::continuously;
            case 3: return LoopingMode::duringKeyPress;
            default: return LoopingMode::none;
        }
    }

    /**
     Create new state vector with a default 44100.0 sample rate.
     */
    VoiceState() : sampleRate_{44100.0}, values_{}
    {
        setDefaults();
    }

    /**
     Create new state vector with a given sample rate.

     @param sampleRate the sample rate of audio being rendered
     */
    explicit VoiceState(double sampleRate, const VoiceStateInitializer& initializer);

    /**
     Obtain a specific generator value.

     @param index the index of the generator
     @returns current value of the generator
     */
    double operator[](Index index) const { return values_[Entity::Generator::indexValue(index)]; }

    double& operator[](Index index) { return values_[Entity::Generator::indexValue(index)]; }

    double sampleRate() const { return sampleRate_; }

    void setRaw(Index  index, int raw) {
        (*this)[index] = Definition::definition(index).convertedValueOf(Amount(raw));
    }

private:

    void setDefaults() {
        setRaw(Index::initialFilterCutoff, 13500);
        setRaw(Index::delayModulatorLFO, -12000);
        setRaw(Index::delayVibratoLFO, -12000);
        setRaw(Index::delayModulatorEnvelope, -12000);
        setRaw(Index::attackModulatorEnvelope, -12000);
        setRaw(Index::holdModulatorEnvelope, -12000);
        setRaw(Index::decayModulatorEnvelope, -12000);
        setRaw(Index::releaseModulatorEnvelope, -12000);
        setRaw(Index::delayVolumeEnvelope, -12000);
        setRaw(Index::attackVolumeEnvelope, -12000);
        setRaw(Index::holdVolumeEnvelope, -12000);
        setRaw(Index::decayVolumeEnvelope, -12000);
        setRaw(Index::releaseVolumeEnvelope, -12000);
        setRaw(Index::midiKey, -1);
        setRaw(Index::midiVelocity, -1);
        setRaw(Index::scaleTuning, 100);
        setRaw(Index::overridingRootKey, -1);
    }

    double sampleRate_;
    std::array<double, static_cast<size_t>(Index::numValues)> values_;
};

} // namespace Render
} // namespace SF2
