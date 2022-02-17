// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <optional>

#include "Entity/Bag.hpp"
#include "IO/File.hpp"
#include "Render/Zone.hpp"

namespace SF2::Render {

/**
 A specialization of a Zone for an Instrument. Instrument zones have a sample buffer.
 */
class InstrumentZone : public Zone {
public:
  /// The type for the optional global InstrumentZone
  using GlobalType = std::optional<const InstrumentZone*>;

  /**
   Construct new zone from entity in file.

   @param gens the vector of generators that define the zone
   @param mods the vector of modulators that define the zone
   @param file the file to work with
   */
  InstrumentZone(GeneratorCollection&& gens, ModulatorCollection&& mods, const IO::File& file) :
  Zone(std::move(gens), std::move(mods), Entity::Generator::Index::sampleID),
  sampleSource_{isGlobal() ? nullptr : &file.sampleSource(resourceLink())}
  {}

  /**
   Apply the zone generator values to the given voice state.

   @param state the state to update
   */
  void apply(State& state) const { Zone::apply(state); }

  /// @returns the sample buffer registered to this zone, or nullptr if this is a global zone.
  const Render::NormalizedSampleSource* sampleSource() const { return sampleSource_; }

private:
  const Render::NormalizedSampleSource* sampleSource_;
};

/// The type for the optional global InstrumentZone
using GlobalInstrumentZone = InstrumentZone::GlobalType;

} // namespace SF2::Render
