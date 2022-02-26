// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <array>

#include "Entity/Generator/Generator.hpp"
#include "Render/Voice/State/GenValue.hpp"

namespace SF2::Render::Voice::State {

/**
 Fixed array of GenValue instances, one for each of the defined SF2 generators.
 */
struct GenValueCollection {
  using Index = Entity::Generator::Index;

  /**
   Obtain a writable GenValue reference via indexing by Entity::Generator::Index enumeration values.

   @param index the generator to get
   @returns GenValue reference
   */
  GenValue& operator[](Index index) { return array_[indexValue(index)]; }

  /**
   Obtain a read-only GenValue reference via indexing by Entity::Generator::Index enumeration values.

   @param index the generator to get
   @returns GenValue reference
   */
  const GenValue& operator[](Index index) const { return array_[indexValue(index)]; }

  /**
   Reset all values to zero.
   */
  void zero() { array_.fill(GenValue()); }

private:
  std::array<GenValue, static_cast<size_t>(Index::numValues)> array_;
};

}
