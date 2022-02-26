// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <functional>
#include <vector>

#include "Logger.hpp"
#include "Entity/Bag.hpp"
#include "Entity/Generator/Generator.hpp"
#include "Entity/Modulator/Modulator.hpp"
#include "IO/ChunkItems.hpp"
#include "IO/File.hpp"
#include "Render/Range.hpp"
#include "Render/Voice/State/State.hpp"

namespace SF2::Render::Zone {

using MIDIRange = Range<int>;

/**
 A zone represents a collection of generator and modulator settings that apply to a range of MIDI key and velocity
 values. There are two types: instrument zones and preset zones. Generator settings for the former specify actual values
 to use, while those in preset zones define adjustments to values set by the instrument.

 Must be derived from.
 */
class Zone
{
public:
  using GeneratorCollection = IO::ChunkItems<Entity::Generator::Generator>::ItemRefCollection;
  using ModulatorCollection = IO::ChunkItems<Entity::Modulator::Modulator>::ItemRefCollection;

  /// A range that always returns true for any MIDI value.
  static MIDIRange const all;

  /**
   Determine if the generator collection and modulator collection combo refers to a global zone. This is the
   case iff the generator collection is empty and the modulator collection is not, or the generator collection does
   not end with a generator of an expected type. Note that in particular if *both* collections are empty, it is *not* a
   global zone here (it should be filtered out elsewhere)

   @param gens collection of generator for the zone
   @param expected the index type of a generator that signals the zone is NOT global
   @param mods collection of modulators for the zone
   */
  static bool IsGlobal(const GeneratorCollection& gens, Entity::Generator::Index expected,
                       const ModulatorCollection& mods) {
    assert(!gens.empty() || !mods.empty());
    return (gens.empty() && !mods.empty()) || (!gens.empty() && gens.back().get().index() != expected);
  }

  /// @returns range of MID key values that this Zone handles
  const MIDIRange& keyRange() const { return keyRange_; }

  /// @returns range of MIDI velocity values that this Zone handles
  const MIDIRange& velocityRange() const { return velocityRange_; }

  /// @returns collection of generators defined for this zone
  const GeneratorCollection& generators() const { return generators_; }

  /// @returns collection of modulators defined for this zone
  const ModulatorCollection& modulators() const { return modulators_; }

  /// @returns true if this is a global zone
  bool isGlobal() const { return isGlobal_; }

  /**
   Determines if this zone applies to a given MIDI key/velocity pair. NOTE: this should not be called for a global
   zone, though technically doing so is OK since both key/velocity ranges will be set to `all` by default.

   @param key MIDI key value
   @param velocity MIDI velocity value
   @returns true if so
   */
  bool appliesTo(int key, int velocity) const {
    assert(!isGlobal_); // Global zones do not have ranges
    return keyRange_.contains(key) && velocityRange_.contains(velocity);
  }

protected:

  /**
   Constructor.

   @param gens collection of generator for the zone
   @param mods collection of modulators for the zone
   @param terminal the index type of a generator that signals the zone is NOT global
   */
  Zone(GeneratorCollection&& gens, ModulatorCollection&& mods, Entity::Generator::Index terminal) :
  generators_{std::move(gens)},
  modulators_{std::move(mods)},
  keyRange_{GetKeyRange(generators_)}, velocityRange_{GetVelocityRange(generators_)},
  isGlobal_{IsGlobal(generators_, terminal, modulators_)},
  filterGenerators_{terminal == Entity::Generator::Index::instrument}
  {
    if (generators_.empty() && modulators_.empty()) throw std::runtime_error("empty zone created");
  }

  /**
   Obtain the link to the resource used by this zone. For an instrument zone, this points to the sample buffer to
   use to render sounds. For a preset zone, this points to an instrument. It is undefined to call on a global zone.

   @returns index of the resource that this zone uses
   */
  uint16_t resourceLink() const {
    if (isGlobal_)
      throw std::runtime_error("global zones do not have a linked resource");
    const Entity::Generator::Generator& generator{generators_.back().get()};
    assert(generator.index() == Entity::Generator::Index::instrument ||
           generator.index() == Entity::Generator::Index::sampleID);
    return generator.amount().unsignedAmount();
  }

private:

  /**
   Obtain a key range from a generator collection. Per spec, if it exists it must be the first generator.

   @param generators collection of generators for the zone
   @returns key range if found or `all` if not
   */
  static MIDIRange GetKeyRange(const GeneratorCollection& generators) {
    if (generators.size() > 0 && generators[0].get().index() == Entity::Generator::Index::keyRange) {
      return MIDIRange(generators[0].get().amount());
    }
    return all;
  }

  /**
   Obtain a velocity range from a generator collection. Per spec, if it exists it must be the first OR second
   generator, and it can only be the second if the first is a key range generator.

   @param generators collection of generators for the zone
   @returns velocity range if found or `all` if not
   */
  static MIDIRange GetVelocityRange(const GeneratorCollection& generators) {
    int index = -1;
    if (generators.size() > 1 && generators[0].get().index() == Entity::Generator::Index::keyRange &&
        generators[1].get().index() == Entity::Generator::Index::velocityRange) {
      index = 1;
    }
    else if (generators.size() > 0 && generators[0].get().index() == Entity::Generator::Index::velocityRange) {
      index = 0;
    }
    return index == -1 ? all : MIDIRange(generators[size_t(index)].get().amount());
  }

  GeneratorCollection generators_;
  ModulatorCollection modulators_;
  MIDIRange keyRange_;
  MIDIRange velocityRange_;
  bool isGlobal_;
  bool filterGenerators_;

  inline static Logger log_{Logger::Make("Render", "Zone")};
};

} // namespace SF2::Render
