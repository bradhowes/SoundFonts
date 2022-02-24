// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Entity/Bag.hpp"
#include "Render/SampleSourceCollection.hpp"
#include "Render/Zone/Zone.hpp"

namespace SF2::Render::Zone {

/**
 A specialization of a Zone for an Instrument. Non-global instrument zones must have a sample source.
 */
class Instrument : public Zone {
public:

  /**
   Construct new instrument zone from entity in file.

   @param gens the vector of generators that define the zone
   @param mods the vector of modulators that define the zone
   @param sampleSources the source fo
   */
  Instrument(GeneratorCollection&& gens, ModulatorCollection&& mods, const SampleSourceCollection& sampleSources) :
  Zone(std::forward<decltype(gens)>(gens), std::forward<decltype(mods)>(mods), Entity::Generator::Index::sampleID),
  sampleSource_{isGlobal() ? nullptr : &sampleSources[resourceLink()]}
  {}

  /// @returns the sample buffer registered to this zone. Throws exception if zone is global
  const Render::NormalizedSampleSource& sampleSource() const {
    if (sampleSource_ == nullptr) throw std::runtime_error("global instrument zone has no sample source");
    return *sampleSource_;
  }

private:
  const Render::NormalizedSampleSource* sampleSource_;
};

} // namespace SF2::Render
