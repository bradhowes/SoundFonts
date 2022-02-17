// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <optional>

#include "Entity/Bag.hpp"
#include "IO/File.hpp"
#include "Render/InstrumentCollection.hpp"
#include "Render/Zone.hpp"

namespace SF2::Render {

/**
 A specialization of a Zone for a Preset. Non-global Preset zones refer to an Instrument.
 */
class PresetZone : public Zone {
public:
  /// The type for the optional global PresetZone
  using GlobalType = std::optional<const PresetZone*>;

  /**
   Construct new zone from entity in file.

   @param gens the vector of generators that define the zone
   @param mods the vector of modulators that define the zone
   @param instruments to collection of instruments found in the file
   */
  PresetZone(GeneratorCollection&& gens, ModulatorCollection&& mods, const Render::InstrumentCollection& instruments) :
  Zone(std::move(gens), std::move(mods), Entity::Generator::Index::instrument),
  instrument_{isGlobal() ? nullptr : &instruments[resourceLink()]}
  {}

  /**
   Apply the zone generator values to the given voice state. Unlike instrument zones, those of a Preset only refine
   existing values.

   @param state the state to update
   */
  void refine(State& state) const { Zone::refine(state); }

  /// @returns the Instrument configured for this zone
  const Render::Instrument& instrument() const { assert(instrument_ != nullptr); return *instrument_; }

private:
  const Render::Instrument* instrument_;
};

/// The type for the optional global PresetZone
using GlobalPresetZone = PresetZone::GlobalType;

} // namespace SF2::Render
