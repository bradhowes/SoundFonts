// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <optional>

#include "Entity/Bag.hpp"
#include "IO/File.hpp"
#include "Render/InstrumentCollection.hpp"
#include "Render/Zones/Zone.hpp"

namespace SF2::Render::Zones {

/**
 A specialization of a Zone for a Preset. Non-global Preset zones must refer to an Instrument.
 */
class Preset : public Zone {
public:

  /**
   Construct new zone from entity in file.

   @param gens the vector of generators that define the zone
   @param mods the vector of modulators that define the zone
   @param instruments to collection of instruments found in the file
   */
  Preset(GeneratorCollection&& gens, ModulatorCollection&& mods, const Render::InstrumentCollection& instruments) :
  Zone(std::forward<decltype(gens)>(gens), std::forward<decltype(mods)>(mods), Entity::Generator::Index::instrument),
  instrument_{isGlobal() ? nullptr : &instruments[resourceLink()]}
  {}

  /// @returns the Instrument configured for this zone
  const Render::Instrument& instrument() const { assert(instrument_ != nullptr); return *instrument_; }

private:
  const Render::Instrument* instrument_;
};

} // namespace SF2::Render
