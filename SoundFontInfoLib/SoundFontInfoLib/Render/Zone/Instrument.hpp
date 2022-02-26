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
  const Render::Voice::Sample::NormalizedSampleSource& sampleSource() const {
    if (sampleSource_ == nullptr) throw std::runtime_error("global instrument zone has no sample source");
    return *sampleSource_;
  }

  /**
   Apply the instrument zone to the given voice state. Sets the nominal value of the generators in the zone.

   @param state the voice state to update
   */
  void apply(Voice::State::State& state) const
  {
    // Generator state settings
    std::for_each(generators().begin(), generators().end(), [&](const Entity::Generator::Generator& generator) {
      log_.debug() << "setting " << generator.name() << " = " << generator.value() << std::endl;
      state.setValue(generator.index(), generator.value());
    });

    // Modulator definitions
    std::for_each(modulators().begin(), modulators().end(), [&](const Entity::Modulator::Modulator& modulator) {
      log_.debug() << "adding mod " << modulator.description() << std::endl;
      state.addModulator(modulator);
    });
  }

private:
  const Render::Voice::Sample::NormalizedSampleSource* sampleSource_;

  inline static Logger log_{Logger::Make("Render", "Zone::Instrument")};
};

} // namespace SF2::Render
