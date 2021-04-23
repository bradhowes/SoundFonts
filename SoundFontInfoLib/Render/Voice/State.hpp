// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cassert>
#include <forward_list>
#include <iostream>
#include <vector>

#include "Logger.hpp"
#include "Types.hpp"
#include "Entity/Generator/Generator.hpp"
#include "Render/MIDI/Channel.hpp"
#include "Render/Modulator.hpp"
#include "Render/Voice/Values.hpp"

namespace SF2 {
namespace Render {
namespace Voice {

class Setup;

/**
 Generator state values for a rendering voice. These are the values from generators. There is the initial state which is
 the default values. Next, there are instrument generators from the zones that match the MIDI key/velocity values of a
 MIDI event. These can override any default values. Finally, there are the preset generators which refine any values by
 adding to them. Note that not all generators are available for refining. Those that are return true from
 `Generator::Definition::isAvailableInPreset`.
 */
class State
{
public:
    using Amount = Entity::Generator::Amount;
    using Index = Entity::Generator::Index;
    using Definition = Entity::Generator::Definition;

    /**
     These are values for the sampleModes (#54) generator.

     - none -- rendering does not loop
     - continuously -- loop as long as the envelope allows
     - duringKeyPress -- loop only while they key is down
     */
    enum LoopingMode {
        none = 0,
        continuously = 1,
        duringKeyPress = 3
    };

    /**
     Mock constructor -- only used in unit tests.
     */
    State(double sampleRate, const MIDI::Channel& channel, UByte key, UByte velocity) :
    sampleRate_{sampleRate}, channel_{channel}, key_{key}, velocity_{velocity} {
        values_.fill(0.0);
    }

    /**
     Create new state vector with a given sample rate.

     @param sampleRate the sample rate of audio being rendered
     */
    State(double sampleRate, const MIDI::Channel& channel, const Setup& setup);

    /**
     Set a generator value.

     @param index the generator to set
     @param value the value to use
     */
    void setValue(Index index, int value) {
        size_t pos{Entity::Generator::indexValue(index)};
        if (values_[pos] != value) {
            log_.debug() << "setting " <<  Entity::Generator::Definition::definition(index).name() << " = "
            << value << std::endl;
            values_[pos] = value;
        }
    }

    /// @returns looping mode of the sample being rendered
    LoopingMode loopingMode() const {
        switch (unmodulated(Index::sampleModes)) {
            case 1: return LoopingMode::continuously;
            case 3: return LoopingMode::duringKeyPress;
            default: return LoopingMode::none;
        }
    }

    /**
     Modify a generator value. Adds the given value to the current generator value.

     @param index the generator to modify
     @param value the value to use
     */
    void adjustValue(Index index, int value) {
        log_.debug() << "adjusting " <<  Entity::Generator::Definition::definition(index).name() << " by "
        << value << std::endl;
        values_[Entity::Generator::indexValue(index)] += value;
    }

    /**
     Obtain a generator value after applying any registered modulators to it.

     @param index the index of the generator
     @returns current value of the generator
     */
    double modulated(Index index) const {
        double value = values_[Entity::Generator::indexValue(index)];
        for (const auto& mod : valueModulators_[indexValue(index)]) {
            value += mod.get().value();
        }
        return value;
    }

    /**
     Obtain a generator value without any modulation applied to it. This is the original result from the zone generator
     definitions. Most of the time, the `modulated` method is what is desired in order to account for any MIDI
     controller values.

     @param index the index of the generator
     @returns current value of the generator
     */
    int unmodulated(Index index) const { return values_[indexValue(index)]; }

    /// @returns sample rate defined at construction
    double sampleRate() const { return sampleRate_; }

    /// @returns fundamental pitch to generate when rendering
    double pitch() const {
        auto forced = unmodulated(Index::forcedMIDIKey);
        auto value = (forced >= 0) ? forced : key_;     // MIDI key is in semitones
        auto coarseTune = modulated(Index::coarseTune); // semitones
        auto fineTune = modulated(Index::fineTune);     // cents (1/100th of a semitone)
        return value + coarseTune + fineTune / 100.0;
    }

    /// @returns key velocity to use when calculating attenuation
    int velocity() const {
        auto value = unmodulated(Index::forcedMIDIVelocity);
        return (value >= 0) ? value : velocity_;
    }

    /// @returns key value to use
    int key() const {
        auto value = unmodulated(Index::forcedMIDIKey);
        return (value >= 0) ? value : key_;
    }

    /**
     Install a modulator.

     @param modulator the modulator to install
     */
    void addModulator(const Entity::Modulator::Modulator& modulator);

    /// @returns the MIDI channel state associated with the rendering
    const MIDI::Channel& channel() const { return channel_; }

private:

    static size_t indexValue(Index index) { return static_cast<size_t>(index); }

    const MIDI::Channel& channel_;

    using ValueArray = std::array<int, static_cast<size_t>(Index::numValues)>;

    /// Collection of generator values that were set by zones.
    ValueArray values_;

    using ModulatorLinkedList = std::forward_list<std::reference_wrapper<Render::Modulator const>>;
    using ValueModulatorArray = std::array<ModulatorLinkedList, static_cast<size_t>(Index::numValues)>;

    /// Collection of modulator lists that affect a given generator value during runtime.
    ValueModulatorArray valueModulators_;

    double sampleRate_;
    UByte key_;
    UByte velocity_;

    std::vector<Modulator> modulators_;

    inline static Logger log_{Logger::Make("Render.Voice", "State")};
};

} // namespace Voice
} // namespace Render
} // namespace SF2
