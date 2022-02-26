// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <list>
#include <forward_list>

#include "Types.hpp"

namespace SF2::Render::Voice::State {

struct GenValue {
  using ModulatorIndexLinkedList = std::forward_list<size_t>;

  int unmodulated() const { return value + adjustment; }

  Float modulated() const { return value + adjustment + sumMods; }

  int value{0};
  int adjustment{0};
  Float sumMods{0.0};
  ModulatorIndexLinkedList mods{};
};

}
