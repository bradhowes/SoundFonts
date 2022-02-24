// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Bag.hpp"
#include "IO/File.hpp"
#include "Render/InstrumentCollection.hpp"
#include "Render/Zone/Zone.hpp"

namespace SF2::Render::Zone {

/**
 A specialization of a Zone for a Preset. Non-global Preset zones must refer to an Instrument.
 */
class Preset : public Zone {
public:

  /**
   Construct new preset zone from entity in file.

   @param gens the vector of generators that define the zone
   @param mods the vector of modulators that define the zone
   @param instruments collection of instrument definitions found in the file
   */
  Preset(GeneratorCollection&& gens, ModulatorCollection&& mods, const Render::InstrumentCollection& instruments) :
  Zone(std::forward<decltype(gens)>(gens), std::forward<decltype(mods)>(mods), Entity::Generator::Index::instrument),
  instrument_{isGlobal() ? nullptr : &instruments[resourceLink()]}
  {}

  /// @returns the Instrument configured for this zone. Throws exception if zone is global.
  const Render::Instrument& instrument() const {
    if (instrument_ == nullptr) throw std::runtime_error("global preset zone has no instrument");
    return *instrument_;
  }

private:
  const Render::Instrument* instrument_;
};

} // namespace SF2::Render
