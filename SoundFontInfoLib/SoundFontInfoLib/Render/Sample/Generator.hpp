// Copyright © 2020 Brad Howes. All rights reserved.

#pragma once

#include <os/log.h>
#include <os/signpost.h>
#include <AudioToolbox/AUParameters.h>
#include <vector>

#include "DSP/DSP.hpp"
#include "Entity/SampleHeader.hpp"
#include "Render/Voice/State.hpp"

namespace SF2::Render::Sample {

/**
 Interface class to generate samples when rendering audio. Relies on template instance to do the actual
 work. Done in this manner to avoid virtual dispatch on call, since all "normal" SF2 processing involves the
 Source::Interpolated class, but testing is better suited with alternatives such as Source::Constant or Source::Sine.

 - S: the source of the sample values
 */
template <typename S> class Generator {
public:

  /**
   Construct new value generator.

   @param source the source to use for the values
   */
  Generator(S&& source) : source_{std::move(source)} {}

  /**
   Obtain the next sample value to use for audio rendering.

   @param pitchAdjustment value to add to the fundamental pitch of the key being played
   @param canLoop true if the generator is permitted to loop for more samples
   @returns new sample value
   */
  double generate(double pitchAdjustment, bool canLoop) { return source_.generate(pitchAdjustment, canLoop); }

private:
  S source_;
};

} // namespace SF2::Render::aSample
