// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <array>

#include "Entity/Generator/Generator.hpp"
#include "Render/Voice/State/GenValue.hpp"

namespace SF2::Render::Voice::State {

struct GenValueCollection {
  using Index = Entity::Generator::Index;

  GenValue& operator[](Index index) { return array_[indexValue(index)]; }

  const GenValue& operator[](Index index) const { return array_[indexValue(index)]; }

  void zero() { array_.fill(GenValue()); }

private:
  std::array<GenValue, static_cast<size_t>(Index::numValues)> array_;
};

}
