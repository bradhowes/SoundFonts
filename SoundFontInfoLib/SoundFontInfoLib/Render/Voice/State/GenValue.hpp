// Copyright © 2022 Brad Howes. All rights reserved.

#pragma once

#include <list>
#include <forward_list>

#include "Types.hpp"
#include "Utils/ListNodeAllocator.hpp"

namespace SF2::Render::Voice::State {

/**
 A runtime generator value. Contains three components:

 - value -- set by an instrument zone generator
 - adjustment -- added to by a preset zone generator
 - sumMods -- contributions from modulators
 */
struct GenValue {
  using Allocator = Utils::ListNodeAllocator<size_t>;
  using ModulatorIndexLinkedList = std::list<size_t, Allocator>;
  inline static Allocator allocator = Allocator(128);

  /**
   Construct a new value
   */
  GenValue() : mods{allocator} {}

  /// @returns generator value as defined by zones (no modulators).
  int unmodulated() const { return value + adjustment; }

  /// @returns generator value that includes modulator contributions
  Float modulated() const { return unmodulated() + sumMods; }

  int value{0};
  int adjustment{0};
  Float sumMods{0.0};

  ModulatorIndexLinkedList mods;
};

}
