// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <optional>

#include "Entity/Bag.hpp"
#include "IO/File.hpp"
#include "Render/Zones/Zone.hpp"

namespace SF2::Render::Zones {

/**
 A specialization of a Zone for an Instrument. Non-global instrument zones must have a sample source.
 */
class Instrument : public Zone {
public:

  /**
   Construct new zone from entity in file.

   @param gens the vector of generators that define the zone
   @param mods the vector of modulators that define the zone
   @param file the file to work with
   */
  Instrument(GeneratorCollection&& gens, ModulatorCollection&& mods, const IO::File& file) :
  Zone(std::move(gens), std::move(mods), Entity::Generator::Index::sampleID),
  sampleSource_{isGlobal() ? nullptr : &file.sampleSource(resourceLink())}
  {}

  /// @returns the sample buffer registered to this zone, or nullptr if this is a global zone.
  const Render::NormalizedSampleSource& sampleSource() const { assert(sampleSource_ != nullptr); return *sampleSource_; }

private:
  const Render::NormalizedSampleSource* sampleSource_;
};

} // namespace SF2::Render
