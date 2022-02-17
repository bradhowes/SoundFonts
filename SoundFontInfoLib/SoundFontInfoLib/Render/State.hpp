// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <cassert>
#include <forward_list>
#include <iostream>
#include <numeric>
#include <vector>

#include "Logger.hpp"
#include "Types.hpp"
#include "Entity/Generator/Generator.hpp"
#include "MIDI/Channel.hpp"
#include "Render/Modulator.hpp"

namespace SF2::Render {

class Config;

/**
 Generator values for a rendering voice. Most of the values originally come from generators defined in an SF2
 instrument or preset entity, with default values used if not explicitly set. Values can change over time via one or
 more modulators being applied to them, but the internal state is always read-only during the life of a Voice to which
 it uniquely belongs.
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
   - activeEnvelope -- loop as long as the envelope allows
   - duringKeyPress -- loop only while they key is down
   */
  enum LoopingMode {
    none = 0,
    activeEnvelope = 1,
    duringKeyPress = 3
  };

  /**
   Create new state vector with a given sample rate.

   @param sampleRate the sample rate of audio being rendered
   @param channel the MIDI channel that is in control
   */
  State(double sampleRate, const MIDI::Channel& channel) : sampleRate_{sampleRate}, channel_{channel} {}

  void configure(const Config& config);
  
  /**
   Set a generator value. Should only be called with a value from an InstrumentZone. It can be set twice, once by a
   global instrument generator setting, and again by a non-global instrument generator setting, the latter one
   replacing the first.

   @param gen the generator to set
   @param value the value to use
   */
  void setPrincipleValue(Index gen, int value) {
    log_.debug() << "setting " << Definition::definition(gen).name() << " = " << value << std::endl;
    gens_[indexValue(gen)].principle = value;
  }

  /**
   Set a generator's adjustment value. Should only be called with a value from a PresetZone. It can be invoked twice,
   once by a global preset setting, and again by a non-global preset generator setting, the latter one replacing the
   first.

   @param gen the generator to set
   @param value the value to use
   */
  void setAdjustmentValue(Index gen, int value) {
    log_.debug() << "adjusting " << Definition::definition(gen).name() << " by " << value << std::endl;
    gens_[indexValue(gen)].adjustment = value;
  }

  /**
   Install a modulator.

   @param modulator the modulator to install
   */
  void addModulator(const Entity::Modulator::Modulator& modulator);

  /**
   Obtain a generator value without any modulation applied to it. This is the original result from the zone generator
   definitions and so it is expressed as an integer. Most of the time, the `modulated` method is what is desired in
   order to account for any MIDI controller values.

   @param gen the index of the generator
   @returns configured value of the generator
   */
  int unmodulated(Index gen) const {
    auto& value{gens_[indexValue(gen)]};
    return value.principle + value.adjustment;
  }

  /**
   Obtain a generator value after applying any registered modulators to it. Due to the modulation calculations this
   returns a floating-point value, but the value has not been converted into any particular unit and should
   still reflect the definitions found in the spec for the given index.

   @param gen the index of the generator
   @returns current value of the generator
   */
  double modulated(Index gen) const {

    // Most of the time there are no modulators.
    auto& genMods{gens_[indexValue(gen)].mods};
    auto value = unmodulated(gen);
    if (genMods.empty()) return value;

    // Accumulate changes to the state value from the registered modulators
    auto modSum = [this](double value, size_t mod) { return value + modulators_[mod].value(); };
    return std::accumulate(genMods.begin(), genMods.end(), value, modSum);
  }

  /// @returns fundamental pitch in semitones to generate when rendering
  double pitch() const {
    auto pitch = key();
    auto coarseTune = modulated(Index::coarseTune); // semitones
    auto fineTune = modulated(Index::fineTune);     // cents (1/100th of a semitone)
    return pitch + coarseTune + fineTune / 100.0;
  }

  /// @returns MIDI key value to use (also pitch in semitones)
  int key() const {
    int value = unmodulated(Index::forcedMIDIKey);
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
      case 1: return LoopingMode::activeEnvelope;
      case 3: return LoopingMode::duringKeyPress;
      default: return LoopingMode::none;
    }
  }

  /// @returns the MIDI channel state associated with the rendering
  const MIDI::Channel& channel() const { return channel_; }

  /// @returns sample rate defined at construction
  double sampleRate() const { return sampleRate_; }

private:

  using ModulatorIndexLinkedList = std::forward_list<size_t>;

  // Three components make up a generator value:
  // - the principle or main value from an instrument zone
  // - any adjustment value from a preset zone
  // - zero or more modulator indices
  struct GenValue {
    int principle{0};
    int adjustment{0};
    ModulatorIndexLinkedList mods{};
  };

  void setDefaults();
  void linkModulators();

  double envelopeSustainLevel(Index gen) const {
    assert(gen == Index::sustainVolumeEnvelope || gen == Index::sustainModulatorEnvelope);
    return 1.0 - modulated(gen) / 1000.0;
  }

  /**
   Obtain a generator value that is scaled by the MIDI key value. Per the spec, key 60 is unchanged. Keys higher will
   scale positively, and keys lower than 60 will scale negatively.

   @param gen the generator holding the timecents/semitone scaling factor
   @returns result of generator value x (60 - key)
   */
  double keyedEnvelopeModulator(Index gen) const {
    assert(gen == Index::midiKeyToVolumeEnvelopeHold ||
           gen == Index::midiKeyToVolumeEnvelopeDecay ||
           gen == Index::midiKeyToModulatorEnvelopeHold ||
           gen == Index::midiKeyToModulatorEnvelopeDecay);
    return modulated(gen) * (60 - key());
  }

  static size_t indexValue(Index gen) { return static_cast<size_t>(gen); }

  const MIDI::Channel& channel_;

  using GenValueArray = std::array<GenValue, static_cast<size_t>(Index::numValues)>;

  /// Collection of generator values
  GenValueArray gens_;

  /// Collection of modulators defined by instrument and preset zones.
  std::vector<Modulator> modulators_{};

  double sampleRate_;
  int key_;
  int velocity_;

  inline static Logger log_{Logger::Make("Render.Voice", "State")};
};

} // namespace SF2::Render
