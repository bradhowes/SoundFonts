// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <array>
#include <string>

#include "Types.hpp"
#include "IO/Pos.hpp"
#include "Entity/Generator/Definition.hpp"
#include "Entity/Generator/Index.hpp"
#include "Entity/Modulator/Source.hpp"
#include "Entity/Modulator/Transform.hpp"

/**
 Classes involved in describing an SF2 modulator. A modulator uses a value from a source to modulate a specific
 generator's value.
 */
namespace SF2::Entity::Modulator {

/**
 Memory layout of a 'pmod'/'imod' entry. The size of this is defined to be 10.
 
 Defines a mapping of a modulator to a generator so that a modulator can affect the value given by a generator. Per the
 spec a modulator can have two sources. If the first one is 'none', then the modulator will always return 0.0. The
 second one is optional -- if it exists then it will scale the result of the previous source value. Otherwise, it just
 acts as if the source returned 1.0.
 
 Per the spec, modulators are unique if they do not share the same sfModSrcOper, sfModDestOper, sfModAmtSrcOper values.
 If there are duplicates, the second occurrence wins.
 */
class Modulator {
public:
  static constexpr size_t size = 10;

  /**
   Default modulators that are predefined for every instrument. These get copied over to each voice's State before the
   preset/instrument configurations are applied.
   */
  static const std::array<Modulator, size> defaults;
  
  /**
   Construct instance from contents of SF2 file.
   
   @param pos location to read from
   */
  explicit Modulator(IO::Pos& pos) {
    assert(sizeof(*this) == size);
    pos = pos.readInto(*this);
  }
  
  /**
   Construct instance from values. Used to define default mods and support unit tests.
   */
  Modulator(Source modSrcOper, Generator::Index dest, int16_t amount, Source modAmtSrcOper, Transform transform) :
  sfModSrcOper{modSrcOper}, sfModDestOper{static_cast<uint16_t>(dest)}, modAmount{amount},
  sfModAmtSrcOper{modAmtSrcOper}, sfModTransOper{transform} {}
  
  /// @returns the source of data for the modulator
  const Source& source() const { return sfModSrcOper; }
  
  /// @returns true if this modulator is the source of a value for another modulator
  bool hasModulatorDestination() const { return (sfModDestOper & (1 << 15)) != 0; }
  
  /// @returns true if this modulator directly affects a generator value
  bool hasGeneratorDestination() const { return !hasModulatorDestination(); }
  
  /// @returns the destination (generator) for the modulator
  Generator::Index generatorDestination() const {
    assert(hasGeneratorDestination() && sfModDestOper < size_t(Generator::Index::numValues));
    return Generator::Index(sfModDestOper);
  }

  /// @returns the index of the destination modulator. This is the index in the pmod/imod bag.
  size_t linkDestination() const {
    assert(hasModulatorDestination());
    return size_t(sfModDestOper ^ (1 << 15));
  }
  
  /// @returns the maximum deviation that a modulator can apply to a generator
  int16_t amount() const { return modAmount; }
  
  /// @returns the second source of data for the modulator
  const Source& amountSource() const { return sfModAmtSrcOper; }
  
  /// @returns the transform to apply to values created by the modulator
  const Transform& transform() const { return sfModTransOper; }
  
  std::string description() const;
  
  bool operator ==(const Modulator& rhs) const {
    return (sfModSrcOper == rhs.sfModSrcOper && sfModDestOper == rhs.sfModDestOper &&
            sfModAmtSrcOper == rhs.sfModAmtSrcOper);
  }
  
  bool operator !=(const Modulator& rhs) const {  return !operator==(rhs); }
  
  void dump(const std::string& indent, size_t index) const;
  
private:
  Source sfModSrcOper;
  uint16_t sfModDestOper;
  int16_t modAmount;
  Source sfModAmtSrcOper;
  Transform sfModTransOper;
};

} // end namespace SF2::Entity::Modulator
