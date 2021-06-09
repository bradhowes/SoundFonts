// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <cstdint>
#include <string>

#include "Entity/Entity.hpp"
#include "IO/Pos.hpp"

namespace SF2::Entity {

/**
 Memory layout of a 'ibag/pbag' entry in a sound font resource. Used to access packed values from a
 resource. Per spec, the size of this must be 4. The wGenNdx and wModNdx properties contain the first index
 of the generator/modulator that belongs to the instrument/preset zone. The number of generator or
 modulator settings is found by subtracting index value of this instance from the index value of the
 subsequent instance. This is guaranteed to be safe in a well-formed SF2 file, as all collections that
 operate in this way have a terminating instance whose index value is the total number of generators or
 modulators in the preset or instrument zones.
 */
class Bag : Entity {
public:
  constexpr static size_t size = 4;

  /**
   Constructor that reads from file.

   @param pos location to read from
   */
  explicit Bag(IO::Pos& pos) {
    assert(sizeof(*this) == 4);
    pos = pos.readInto(*this);
  }

  /// @returns first generator index in this collection
  uint16_t firstGeneratorIndex() const { return wGenNdx; }

  /// @returns number of generators in this collection
  uint16_t generatorCount() const { return calculateSize(next(this).firstGeneratorIndex(), firstGeneratorIndex()); }
  
  /// @returns first modulator index in this collection
  uint16_t firstModulatorIndex() const { return wModNdx; }

  /// @returns number of modulators in this collection
  uint16_t modulatorCount() const { return calculateSize(next(this).firstModulatorIndex(), firstModulatorIndex()); }

  /**
   Utility for displaying bag contents on output stream.

   @param indent the prefix to write out before each line
   @param index a prefix index value to write out before each lines
   */
  void dump(const std::string& indent, int index) const;

private:
  uint16_t wGenNdx;
  uint16_t wModNdx;
};

} // end namespace SF2::Entity
