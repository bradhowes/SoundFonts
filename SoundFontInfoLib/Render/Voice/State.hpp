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
        setDefaults();
    }

    /**
     Create new state vector with a given sample rate.

     @param sampleRate the sample rate of audio being rendered
     */
    State(double sampleRate, const MIDI::Channel& channel, const Setup& setup);

    /**
     Set a generator value. Instrument zones set generator values; preset zones set their adjustments. It can be set
     twice, once by a global instrument generator setting, and again by a non-global instrument generator setting.

     @param index the generator to set
     @param value the value to use
     */
    void setValue(Index index, int value) {
        size_t pos{indexValue(index)};
        if (values_[pos] != value) {
            log_.debug() << "setting " <<  Entity::Generator::Definition::definition(index).name() << " = "
            << value << std::endl;
            values_[pos] = value;
        }
    }

    /**
     Set a generator's adjustment value. Instrument zones set generator values; preset zones set their adjustments. It
     can be set twice, once by a global preset generator setting, and again by a non-global preset generator setting.

     @param index the generator to set
     @param value the value to use
     */
    void adjustValue(Index index, int value) {
        log_.debug() << "adjusting " <<  Entity::Generator::Definition::definition(index).name() << " by "
        << value << std::endl;
        adjustments_[indexValue(index)] = value;
    }

    /**
     Install a modulator.

     @param modulator the modulator to install
     */
    void addModulator(const Entity::Modulator::Modulator& modulator);

    /**
     Obtain a generator value after applying any registered modulators to it. Due to the modulation calculations this
     returns a floating-point value, but the value has not been converted from/into any particular units and should
     still reflect the definitions found in the spec.

     @param index the index of the generator
     @returns current value of the generator
     */
    double modulated(Index index) const {
        size_t pos{indexValue(index)};
        double value = values_[pos] + adjustments_[pos];
        for (auto modIndex : valueModulators_[pos]) {
            const Modulator& modulator{modulators_[modIndex]};
            value += modulator.value();
        }
        return value;
    }

    /**
     Obtain a generator value without any modulation applied to it. This is the original result from the zone generator
     definitions and so it is expressed as an integer. Most of the time, the `modulated` method is what is desired in
     order to account for any MIDI controller values.

     @param index the index of the generator
     @returns configured value of the generator
     */
    int unmodulated(Index index) const {
        size_t pos{indexValue(index)};
        return values_[pos] + adjustments_[pos];
    }

    /// @returns fundamental pitch to generate when rendering
    double pitch() const {
        auto forced = unmodulated(Index::forcedMIDIKey);
        auto value = (forced >= 0) ? forced : key_;     // MIDI key is in semitones
        auto coarseTune = modulated(Index::coarseTune); // semitones
        auto fineTune = modulated(Index::fineTune);     // cents (1/100th of a semitone)
        return value + coarseTune + fineTune / 100.0;
    }

    /// @returns key value to use
    int key() const {
        auto value = unmodulated(Index::forcedMIDIKey);
        return (value >= 0) ? value : eventKey();
    }

    /// @returns key velocity to use when calculating attenuation
    int velocity() const {
        auto value = unmodulated(Index::forcedMIDIVelocity);
        return (value >= 0) ? value : eventVelocity();
    }

    /// @returns key from MIDI event that triggered the voice rendering
    int eventKey() const { return key_; }

    /// @returns velocity from MIDI event that triggered the voice rendering
    int eventVelocity() const { return velocity_; }

    /// @returns the adjustment to the volume envelope's hold stage timing based on the MIDI key event
    double keyedVolumeEnvelopeHold() const {
        return keyedEnvelopeModulator(Index::midiKeyToVolumeEnvelopeHold);
    }

    /// @returns the adjustment to the volume envelope's decay stage timing based on the MIDI key event
    double keyedVolumeEnvelopeDecay() const {
        return keyedEnvelopeModulator(Index::midiKeyToVolumeEnvelopeDecay);
    }

    /// @returns the adjustment to the modulator envelope's hold stage timing based on the MIDI key event
    double keyedModulatorEnvelopeHold() const {
        return keyedEnvelopeModulator(Index::midiKeyToModulatorEnvelopeHold);
    }

    /// @returns the adjustment to the modulator envelope's decay stage timing based on the MIDI key event
    double keyedModulatorEnvelopeDecay() const {
        return keyedEnvelopeModulator(Index::midiKeyToModulatorEnvelopeDecay);
    }

    /// @returns the sustain level for the volume envelope (gain)
    double sustainLevelVolumeEnvelope() const { return envelopeSustainLevel(Index::sustainVolumeEnvelope); }

    /// @returns the sustain level for the modulator envelope
    double sustainLevelModulatorEnvelope() const { return envelopeSustainLevel(Index::sustainModulatorEnvelope); }

    /// @returns looping mode of the sample being rendered
    LoopingMode loopingMode() const {
        switch (unmodulated(Index::sampleModes)) {
            case 1: return LoopingMode::continuously;
            case 3: return LoopingMode::duringKeyPress;
            default: return LoopingMode::none;
        }
    }

    /// @returns the MIDI channel state associated with the rendering
    const MIDI::Channel& channel() const { return channel_; }

    /// @returns sample rate defined at construction
    double sampleRate() const { return sampleRate_; }

private:

    void setDefaults();

    double envelopeSustainLevel(Index index) const {
        assert(index == Index::sustainVolumeEnvelope || index == Index::sustainModulatorEnvelope);
        return 1.0 - modulated(index) / 1000.0;
    }

    /**
     Obtain a generator value that is scaled by the MIDI key value. Per the spec, key 60 is unchanged. Keys higher will
     scale positively, and keys lower than 60 will scale negatively.

     @param index the generator holding the timecents/semitone scaling factor
     @returns result of generator value x (60 - key)
     */
    double keyedEnvelopeModulator(Index index) const {
        assert(index == Index::midiKeyToVolumeEnvelopeHold ||
               index == Index::midiKeyToVolumeEnvelopeDecay ||
               index == Index::midiKeyToModulatorEnvelopeHold ||
               index == Index::midiKeyToModulatorEnvelopeDecay);
        return modulated(index) * (60 - key());
    }

    static size_t indexValue(Index index) { return static_cast<size_t>(index); }

    const MIDI::Channel& channel_;

    using ValueArray = std::array<int, static_cast<size_t>(Index::numValues)>;

    /// Collection of generator values that were set by instrument zones.
    ValueArray values_;

    /// Collection of generator adjustments that were set by preset zones.
    ValueArray adjustments_;

    /// Collection of modulators defined by instrument and preset zones.
    std::vector<Modulator> modulators_{};

    using ModulatorIndexLinkedList = std::forward_list<size_t>;
    using ValueModulatorArray = std::array<ModulatorIndexLinkedList, static_cast<size_t>(Index::numValues)>;

    /// Collection of modulator lists that affect a given generator value during runtime.
    ValueModulatorArray valueModulators_{};

    double sampleRate_;
    UByte key_;
    UByte velocity_;

    inline static Logger log_{Logger::Make("Render.Voice", "State")};
};

} // namespace Voice
} // namespace Render
} // namespace SF2
