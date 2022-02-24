// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include "Render/State.hpp"

namespace SF2::Render {

/**
 View of a State that pertains to pitch.
 */
class Pitch
{
public:

  Pitch(const State& state) : state_{state} {}

  Float pitch() const {
    return 0.0;
  }

private:
  const State& state_;
} // namespace SF2::Render
