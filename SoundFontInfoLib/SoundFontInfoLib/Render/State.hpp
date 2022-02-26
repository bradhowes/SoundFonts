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
   Create new state vector with a given sample rate.

   @param sampleRate the sample rate of audio being rendered
   @param channel the MIDI channel that is in control
   */
  State(Float sampleRate, const MIDI::Channel& channel) : sampleRate_{sampleRate}, channel_{channel} {}

  /** Create new state vector for testing purposes.
   @param sampleRate the sample rate of audio being rendered
   @param channel the MIDI channel that is in control
   @param key the MIDI key to use
   @param velocity the MIDI velocity to use
   */
  State(Float sampleRate, const MIDI::Channel& channel, int key, int velocity = 64) :
  sampleRate_{sampleRate}, channel_{channel}, eventKey_{key}, eventVelocity_{velocity}
  {
    setDefaults();
  }

  /**
   Configure the state to be used by a voice for sample rendering.
   */
  void prepareForVoice(const Config& config);

  /**
   Set a generator value. Should only be called with a value from an InstrumentZone. It can be set twice, once by a
   global instrument generator setting, and again by a non-global instrument generator setting, the latter one
   replacing the first.

   @param gen the generator to set
   @param value the value to use
   */
  void setValue(Index gen, int value) {
    log_.debug() << "setting " << Definition::definition(gen).name() << " = " << value << std::endl;
    gens_[gen].value = value;
  }

  /**
   Set a generator's adjustment value. Should only be called with a value from a PresetZone. It can be invoked twice,
   once by a global preset setting, and again by a non-global preset generator setting, the latter one replacing the
   first.

   @param gen the generator to set
   @param value the value to use
   */
  void setAdjustment(Index gen, int value) {
    log_.debug() << "adjust " << Definition::definition(gen).name() << " by " << value << std::endl;
    gens_[gen].adjustment = value;
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
  int unmodulated(Index gen) const { return gens_[gen].unmodulated(); }

  /**
   Obtain a generator value after applying any registered modulators to it. Due to the modulation calculations this
   returns a floating-point value, but the value has not been converted into any particular unit and should
   still reflect the definitions found in the spec for the given index.

   @param gen the index of the generator
   @returns current value of the generator
   */
  Float modulated(Index gen) const {
    // Most of the time there are no modulators.
    auto& genMods{gens_[gen].mods};
    auto value = unmodulated(gen);
    if (genMods.empty()) return value;
    auto modSum = [this](Float value, size_t mod) { return value + modulators_[mod].value(); };
    return std::accumulate(genMods.begin(), genMods.end(), value, modSum);
  }

  /// @returns key value to use for DSP
  int key() const {
    int value = unmodulated(Index::forcedMIDIKey);
    return (value >= 0) ? value : eventKey_;
  }

  /// @returns velocity to use for DSP
  int velocity() const {
    auto value = unmodulated(Index::forcedMIDIVelocity);
    return (value >= 0) ? value : eventVelocity_;
  }

  /// @returns the MIDI channel state associated with the rendering
  const MIDI::Channel& channel() const { return channel_; }

  /// @returns sample rate defined at construction
  Float sampleRate() const { return sampleRate_; }

private:

  using ModulatorIndexLinkedList = std::forward_list<size_t>;

  struct GenValue {
    int value{0};
    int adjustment{0};
    int sumMods{0};
    ModulatorIndexLinkedList mods{};

    int unmodulated() const { return value + adjustment; }
  };

  struct GenValueArray {
    GenValue& operator[](Index index) { return array_[indexValue(index)]; }
    const GenValue& operator[](Index index) const { return array_[indexValue(index)]; }
    void zero() { array_.fill(GenValue()); }
  private:
    std::array<GenValue, static_cast<size_t>(Index::numValues)> array_;
  };

  void setDefaults();
  void linkModulators();

  const MIDI::Channel& channel_;

  /// Collection of generator values
  GenValueArray gens_;

  /// Collection of modulators defined by instrument and preset zones.
  std::vector<Modulator> modulators_{};

  Float sampleRate_;
  int eventKey_;
  int eventVelocity_;

  inline static Logger log_{Logger::Make("Render.Voice", "State")};
};

} // namespace SF2::Render
