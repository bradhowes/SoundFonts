// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Sample/BufferIndex.hpp"
#include "Render/Sample/CanonicalBuffer.hpp"
#include "Render/Sample/PitchControl.hpp"
#include "Render/Sample/Bounds.hpp"
#include "Render/Voice/State.hpp"

namespace SF2::Render::Sample::Source {

class Constant {
public:
  Constant(double value) : value_{value} {}

  double generate(double pitchAdjustment, bool canLoop) {
    return value_;
  }

private:
  double value_;
};

} // namespace SF2::Render::aSample
