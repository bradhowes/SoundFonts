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

class Sine {
public:

  Sine(double dTheta) : theta_{0.0}, dTheta_{dTheta} {}

  double generate(double pitchAdjustment, bool canLoop) {
    auto value = std::sin(theta_);
    theta_ += dTheta_;
    if (theta_ >= DSP::TwoPI) {
      theta_ -= DSP::TwoPI;
    }
    return value;
  }

private:
  double theta_;
  double dTheta_;
};

} // namespace SF2::Render::aSample
